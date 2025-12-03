UCLASS(Abstract)
class ASketchBookCarryPrince : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Backpack;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams BoatMh;

	UFUNCTION(BlueprintCallable)
	void PreEndCutscene(AHazePlayerCharacter CarryPlayer)
	{
		this.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MeshComp.SetRelativeTransform(FTransform::Identity);

		Backpack.AttachToComponent(CarryPlayer.Mesh, n"Backpack", EAttachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintCallable)
	void PostEndCutscene(AActor ShipHull)
	{
		MeshComp.PlaySlotAnimation(BoatMh);
		MeshComp.AttachToComponent(ShipHull.RootComponent, AttachmentRule = EAttachmentRule::KeepWorld);
	}
};
