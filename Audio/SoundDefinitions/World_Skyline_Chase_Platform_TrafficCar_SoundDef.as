
UCLASS(Abstract)
class UWorld_Skyline_Chase_Platform_TrafficCar_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnExploded(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditAnywhere, Meta = (Category = "Positioning"))
	FName AttachComponentName = n"StaticMesh";

	// UPROPERTY(EditAnywhere, Meta = (Category = "Positioning"))
	// bool bUsePlanePositioning = true;

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		ComponentName = AttachComponentName;
		bUseAttach = true;
		return true;
	}

	TArray<FAkSoundPosition> SoundPositions;
	UMeshComponent MeshComp;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		// if(bUsePlanePositioning)
		// {
		// 	MeshComp = Cast<UMeshComponent>(DefaultEmitter.AudioComponent.GetAttachParent());
		// 	DefaultEmitter.AudioComponent.DetachFromParent();
		// 	SoundPositions.SetNum(1);
		// }
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		// Currently won't work, no collision on traffic car meshes

		// if(bUsePlanePositioning)
		// {
		// 	// Just using Mio here is fine, players are close enough together
		// 	const FVector MioPos = Game::GetMio().GetActorLocation();
		// 	FVector ClosestPointOnCollider;

		// 	MeshComp.GetClosestPointOnCollision(MioPos, ClosestPointOnCollider);
		// 	SoundPositions[0].SetPosition(ClosestPointOnCollider);

		// 	DefaultEmitter.AudioComponent.SetMultipleSoundPositions(SoundPositions);

		// }
	}
}