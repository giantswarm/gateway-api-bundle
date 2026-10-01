package basic

import (
	"fmt"
	"testing"
	"time"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
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
}

func TestBasic(t *testing.T) {
	suite.New().
		WithIsUpgrade(isUpgrade).
		WithValuesFile("./values.yaml").
		AfterClusterReady(func() {
			It("should configure the bundle to run on the management cluster", func() {
				cluster := state.GetCluster()
				app := state.GetApplication()

				// The bundle renders HelmReleases on the MC that target the WC through its kubeconfig.
				app.WithInCluster(true).WithInstallNamespace(cluster.Organization.GetNamespace())
				app.Values = fmt.Sprintf("clusterID: %s\norganization: %s\n%s", cluster.Name, cluster.Organization.Name, app.Values)
			})
		}).
		Tests(func() {
			It("should have deployed the bundle app", func() {
				Eventually(helmrelease.IsAppOrHelmReleaseReady(state.GetContext(), state.GetFramework().MC(), state.GetApplication().InstallName, state.GetCluster().Organization.GetNamespace())).
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
					WithTimeout(20 * time.Minute).
					WithPolling(10 * time.Second).
					Should(Succeed(), failurehandler.HelmReleasesNotReady(state.GetFramework(), cluster))
			})
		}).
		Run(t, "Gateway API Bundle Test")
}
