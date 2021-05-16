package v1

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/go-logr/logr"

	corev1 "k8s.io/api/core/v1"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/webhook/admission"
)

type podAnnotator struct {
	Client  client.Client
	decoder *admission.Decoder
	Log     logr.Logger
}

func NewPodAnnotator(c client.Client, log logr.Logger) admission.Handler {
	return &podAnnotator{Client: c, Log: log}
}

func (a *podAnnotator) Handle(ctx context.Context, req admission.Request) admission.Response {
	pod := &corev1.Pod{}
	err := a.decoder.Decode(req, pod)
	if err != nil {
		return admission.Errored(http.StatusBadRequest, err)
	}
	log := a.Log.WithValues("kind", pod.Kind, "name", pod.Name, "namespace", pod.Namespace)
	// mutate the fields in pod
	log.Info("Received request for Mutation")
	marshaledPod, err := json.Marshal(pod)
	if err != nil {
		return admission.Errored(http.StatusInternalServerError, err)
	}
	return admission.PatchResponseFromRaw(req.Object.Raw, marshaledPod)
}

func (a *podAnnotator) InjectDecoder(d *admission.Decoder) error {
	a.decoder = d
	return nil
}
