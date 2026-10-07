package basic

import (
	"fmt"
	"testing"
	"time"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/apimachinery/pkg/types"

	"github.com/giantswarm/apptest-framework/v5/pkg/state"
	"github.com/giantswarm/apptest-framework/v5/pkg/suite"
	"github.com/giantswarm/clustertest/v5/pkg/failurehandler"
	"github.com/giantswarm/clustertest/v5/pkg/helmrelease"
)

const (
	isUpgrade = false
)

// childApps are the appName values of the apps enabled in values.yaml.
var childApps = []string{
	"gateway-api-crds",
	"envoy-gateway",
	"gateway-api-config",
	"cloudwatch-exporter",
}

// iamRoleGVK is the Crossplane IAM Role the bundle renders for cloudwatch-exporter.
var iamRoleGVK = schema.GroupVersionKind{Group: "iam.aws.upbound.io", Version: "v1beta1", Kind: "Role"}

// isConditionTrue reports whether the named status condition of obj is True.
func isConditionTrue(obj *unstructured.Unstructured, conditionType string) bool {
	conditions, _, _ := unstructured.NestedSlice(obj.Object, "status", "conditions")
	for _, c := range conditions {
		cond, ok := c.(map[string]interface{})
		if ok && cond["type"] == conditionType && cond["status"] == "True" {
			return true
		}
	}
	return false
}

func TestBasic(t *testing.T) {
	suite.New().
		WithIsUpgrade(isUpgrade).
		WithValuesFile("./values.yaml").
		// The bundle renders its children on the MC, so it has to be installed in-cluster
		// rather than through the workload cluster's kubeconfig.
		WithHelmRelease(true).
		WithHelmServiceAccountName("automation").
		Tests(func() {
			It("should have deployed the bundle HelmRelease", func() {
				cluster := state.GetCluster()
				Eventually(helmrelease.IsHelmReleaseReady(state.GetContext(), state.GetFramework().MC(), fmt.Sprintf("%s-gateway-api-bundle", cluster.Name), cluster.Organization.GetNamespace())).
					WithTimeout(5 * time.Minute).
					WithPolling(5 * time.Second).
					Should(BeTrue())
			})

			It("should have all child HelmReleases ready", func() {
				cluster := state.GetCluster()
				children := make([]types.NamespacedName, 0, len(childApps))
				for _, name := range childApps {
					children = append(children, types.NamespacedName{
						Name:      fmt.Sprintf("%s-%s", cluster.Name, name),
						Namespace: cluster.Organization.GetNamespace(),
					})
				}

				Eventually(helmrelease.AreAllReady(state.GetContext(), state.GetFramework().MC(), children)).
					WithTimeout(20*time.Minute).
					WithPolling(10*time.Second).
					Should(Succeed(), failurehandler.HelmReleasesNotReady(state.GetFramework(), cluster))
			})

			It("should have the cloudwatch-exporter IAM role ready", func() {
				cluster := state.GetCluster()
				key := types.NamespacedName{
					Name:      fmt.Sprintf("%s-cloudwatch-exporter", cluster.Name),
					Namespace: cluster.Organization.GetNamespace(),
				}

				Eventually(func(g Gomega) {
					role := &unstructured.Unstructured{}
					role.SetGroupVersionKind(iamRoleGVK)
					g.Expect(state.GetFramework().MC().Get(state.GetContext(), key, role)).To(Succeed())
					g.Expect(isConditionTrue(role, "Ready")).To(BeTrue(), "IAM role %s is not Ready", key)
				}).
					WithTimeout(10 * time.Minute).
					WithPolling(10 * time.Second).
					Should(Succeed())
			})
		}).
		Run(t, "Gateway API Bundle Test")
}
