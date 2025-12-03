#if EDITOR
class UGravityBikeFreeSequenceEditorComponent : UActorComponent
{
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Editor::IsPlaying())
			return;

		auto GravityBike = Cast<AGravityBikeFree>(Owner);

		if(GravityBike == nullptr)
			return;

		// When previewing in the sequencer, remove offsets
		GravityBike.MeshPivot.SetRelativeTransform(FTransform::Identity);
		GravityBike.SkeletalMesh.SetRelativeTransform(FTransform::Identity);
	}
};
#endif