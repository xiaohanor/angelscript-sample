
UCLASS(Abstract)
class UWorld_Island_Rift_Platform_IslandDangerWall_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotEditable)
	UHazeAudioEmitter OpeningEmitter;

	UPROPERTY(NotEditable)
	UHazeAudioEmitter ClosingEmitter;

	UFUNCTION(BlueprintEvent)
	void StartOpening() {}

	UFUNCTION(BlueprintEvent)
	void StartClosing() {}

	private FVector EmitterStartLerpPos;
	private FVector EmitterEndLerpPos;

	private FVector LoopEmitterLocation;
	private FVector OpeningEmitterLocation;
	private FVector ClosingEmitterLocation;	


	private float CycleTimeSeconds = 8.0;
	private float OpeningTime = 0.0;
	private float ClosingTime = 0.0;

	TArray<UStaticMeshComponent> WallMeshes;
	TArray<FAkSoundPosition> WallSoundPositions;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		AKineticMovingActor MovingActor = Cast<AKineticMovingActor>(HazeOwner);

		MovingActor.OnStartForward.AddUFunction(this, n"OnStartClosing");
		MovingActor.OnStartBackward.AddUFunction(this, n"OnStartOpening");

		EmitterStartLerpPos = MovingActor.TargetLocationComp.WorldLocation;
		EmitterEndLerpPos = EmitterStartLerpPos + FVector(1050, 1050, 0.0);

		DefaultEmitter.AudioComponent.SetWorldLocation(EmitterStartLerpPos + FVector(750, 750, 0.0));

		auto Walls = TListedActors<AIslandDangerWall>().GetArray();
		for(auto Wall : Walls)
		{
			WallMeshes.Add(UStaticMeshComponent::Get(Wall, n"StaticMesh"));
		}
		WallSoundPositions.SetNum(WallMeshes.Num() * 2);
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		bUseAttach = false;
		return false;
	}

	UFUNCTION()
	void OnStartOpening()
	{
		OpeningTime = 0.0;
		StartOpening();
	}

	UFUNCTION()
	void OnStartClosing()
	{
		ClosingTime = 0.0;
		StartClosing();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		OpeningEmitterLocation = Math::Lerp(EmitterStartLerpPos, EmitterEndLerpPos, OpeningTime / CycleTimeSeconds);
		OpeningTime += DeltaSeconds;

		ClosingEmitterLocation = Math::Lerp(EmitterStartLerpPos, EmitterEndLerpPos, ClosingTime / CycleTimeSeconds);
		ClosingTime += DeltaSeconds;

		OpeningEmitter.AudioComponent.SetWorldLocation(OpeningEmitterLocation);
		ClosingEmitter.AudioComponent.SetWorldLocation(ClosingEmitterLocation);	
		auto Players = Game::GetPlayers();
		
		for(int i = 0; i < WallSoundPositions.Num(); i += 2)
		{
			auto Wall = WallMeshes[Math::IntegerDivisionTrunc(i, 2)];

			FVector ClosestWallPlayerPos1;
			FVector ClosestWallPlayerPos2;

			const float Dist1 = Wall.GetClosestPointOnCollision(Players[0].ActorLocation, ClosestWallPlayerPos1);
			if(Dist1 < 0 )
				ClosestWallPlayerPos1 = Wall.WorldLocation;

			const float Dist2 = Wall.GetClosestPointOnCollision(Players[1].ActorLocation, ClosestWallPlayerPos2);
			if(Dist2 < 0)
				ClosestWallPlayerPos2 = Wall.WorldLocation;

			WallSoundPositions[i].SetPosition(ClosestWallPlayerPos1);			
			WallSoundPositions[i + 1].SetPosition(ClosestWallPlayerPos2);
		}			

		DefaultEmitter.AudioComponent.SetMultipleSoundPositions(WallSoundPositions, AkMultiPositionType::MultiDirections);	
	}	
}