class AIslandOverseerDynamicForcedTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	EHazePlayer Player;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.InitialStoppedPlayerCapabilities.Add(n"IslandOverseerDynamicForcedTargetPlayerCapability");

	UIslandOverseerDynamicForcedTargetPlayerComponent ForcedTargetComp;
	AHazePlayerCharacter ForcedTargetPlayer;
	float DistanceOffset;
	AAIIslandOverseer Overseer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(Player == EHazePlayer::Mio)
			ForcedTargetPlayer = Game::Mio;
		else 
			ForcedTargetPlayer = Game::Zoe;
			
		ForcedTargetComp = UIslandOverseerDynamicForcedTargetPlayerComponent::GetOrCreate(ForcedTargetPlayer);
		ForcedTargetComp.Targets.Add(this);

		RequestComp.StartInitialSheetsAndCapabilities(ForcedTargetPlayer, this);

		//  Yes yes, ugly bad quick hack to retrieve the Overseer
		if(AttachParentActor != nullptr && AttachParentActor.AttachParentActor != nullptr)
			Overseer = Cast<AAIIslandOverseer>(AttachParentActor.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Overseer != nullptr)
			AttachParentActor.ActorLocation = Overseer.Mesh.GetSocketLocation(n"NeckBase") - FVector::UpVector * 50;
	}
}