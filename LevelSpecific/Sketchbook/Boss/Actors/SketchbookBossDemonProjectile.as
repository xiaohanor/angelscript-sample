UCLASS(Abstract)
class ASketchbookBossDemonProjectile : ASketchbookBossProjectile
{
	FVector TargetLocation;
	float TravelSpeed = 1250;
	FHazeAcceleratedFloat Acceleration;
	default Acceleration.Value = 0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		if(ActorLocation.Distance(TargetLocation) < KINDA_SMALL_NUMBER)
		{
			if(SceneView::IsInView(SceneView::GetFullScreenPlayer(), TargetLocation))
				AudioComponent::PostFireForget(ProjectileImpactAudioEvent, FHazeAudioFireForgetEventParams());
			
			DestroyActor();
		}

		Acceleration.AccelerateTo(1, 2, DeltaSeconds);
		FVector NewLocation = Math::VInterpConstantTo(ActorLocation, TargetLocation, DeltaSeconds, TravelSpeed * Acceleration.Value);
		SetActorLocation(NewLocation);
	}
};