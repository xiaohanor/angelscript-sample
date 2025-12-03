class AGameShowArenaDisplayDecalTrigger : AVolume
{
	default BrushComponent.SetCollisionProfileName(n"Trigger");

	UPROPERTY(EditInstanceOnly)
	AGameShowArenaPlatformArm DisplayTarget;

	UPROPERTY(DefaultComponent)
	UGameShowArenaDisplayDecalPlatformComponent DecalComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DecalComp.AssignTarget(DisplayTarget.PlatformMesh, DisplayTarget.PanelMaterial);
	}

	// UFUNCTION(CallInEditor)
	// void MapDisplayTarget()
	// {
	// 	FHazeTraceSettings Trace;
	// 	Trace.TraceWithChannel(ECollisionChannel::PlayerCharacter);
	// 	Trace.IgnoreActor(this);
	// 	Trace.UseLine();
	// 	auto Results = Trace.QueryTraceMulti(ActorLocation + FVector::UpVector * 500, ActorLocation - FVector::UpVector * 500);
	// 	for (auto Result : Results)
	// 	{
	// 		auto Arm = Cast<AGameShowArenaPlatformArm>(Result.Actor);
	// 		if (Arm != nullptr)
	// 			DisplayTarget = Arm;
	// 	}
	// }
};