
/*
	Optional Actor class to use for the Niagara system that places out meshes on the spline.
*/

UCLASS(Abstract)
class AMeshSplineFollower : ASplineActor
{
	UPROPERTY(DefaultComponent, Attach = Spline)
	UNiagaraComponent MeshEmitter;

#if EDITOR
	default Spline.EditingSettings.bEnableVisualizeScale = true;
	default Spline.EditingSettings.VisualizeScale = 3000.0;
#endif



}