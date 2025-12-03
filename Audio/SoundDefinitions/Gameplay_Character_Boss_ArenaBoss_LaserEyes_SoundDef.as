
UCLASS(Abstract)
class UGameplay_Character_Boss_ArenaBoss_LaserEyes_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void LaserEyesOverheat(){}

	UFUNCTION(BlueprintEvent)
	void LaserEyesAttackStarted(){}

	/* END OF AUTO-GENERATED CODE */

	AArenaBoss ArenaBoss;
	FBoxSphereBounds LaserAudioBounds;

	UPROPERTY(BlueprintReadOnly)
	UHazeAudioEmitter HeadEmitter;

	UPrimitiveComponent LaserPassbyTrigger;

	UFUNCTION(BlueprintEvent)
	void LaserSweepStarted() {}

	UFUNCTION(BlueprintEvent)
	void LaserSweepChangeDirection() {}

	bool bHasStartedLaserSweep = false;
	TArray<FAkSoundPosition> LaserSoundPositions;

	FVector GetLaserStart() const property
	{
		return Math::Lerp(ArenaBoss.LaserEye1.WorldLocation, ArenaBoss.LaserEye2.WorldLocation, 0.5);
	}

	FVector GetLaserEnd() const property
	{
		return Math::Lerp(ArenaBoss.LaserEye1.WorldLocation + (ArenaBoss.LaserEye1.WorldRotation.ForwardVector * 3000), ArenaBoss.LaserEye2.WorldLocation + (ArenaBoss.LaserEye2.WorldRotation.ForwardVector * 3000), 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		ArenaBoss = Cast<AArenaBoss>(HazeOwner);
		LaserPassbyTrigger = UPrimitiveComponent::Get(ArenaBoss, n"LaserEyesPassbyTrigger");	
		LaserPassbyTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnPlayerOverlapPassbyTrigger");

		LaserSoundPositions.SetNum(2);

		HeadEmitter.AudioComponent.AttachToComponent(ArenaBoss.HeadActor.HeadRoot);
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		if(EmitterName == n"HeadEmitter")
		{
			bUseAttach = false;
			return false;
		}

		return true;

	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return ArenaBoss.CurrentState == EArenaBossState::LaserEyes;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return ArenaBoss.CurrentState != EArenaBossState::LaserEyes;
	}

	UFUNCTION()
	void LaserEyesSweepStarted(FArenaBossLaserEyesSweepData Data)
	{
		if(bHasStartedLaserSweep)
		{
			LaserSweepChangeDirection();
			return;
		}

		// LaserAudioBounds.Origin = Math::Lerp((ArenaBoss.LaserEye1.WorldLocation + (ArenaBoss.LaserEye1.RelativeRotation.ForwardVector * 3000)), ArenaBoss.LaserEye2.WorldLocation + (ArenaBoss.LaserEye2.RelativeRotation.ForwardVector * 3000), 0.5);
		// LaserAudioBounds.BoxExtent = FVector(10000, 150, 150);

		LaserSweepStarted();
		bHasStartedLaserSweep = true;		
	}

	UFUNCTION()
	void OnPlayerOverlapPassbyTrigger(UPrimitiveComponent Primitive, AActor OtherActor, UPrimitiveComponent OtherPrimitive, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr)
		{
			PlayerOverlapPassby(Player, ArenaBoss.LaserEyesSpins);
		}
	}

	UFUNCTION(BlueprintEvent)
	void PlayerOverlapPassby(AHazePlayerCharacter Player, int SpinCount) {}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		// Can be nullptr in cooks it seems.
		if (ArenaBoss.LaserEye1 == nullptr)
			return;

		if(bHasStartedLaserSweep)
		{
			HeadEmitter.AudioComponent.SetWorldRotation(ArenaBoss.LaserEye1.WorldRotation);

			LaserPassbyTrigger.SetWorldRotation(ArenaBoss.LaserEye1.WorldRotation);
			//Debug::DrawDebugLine(LineStart, LineEnd, FLinearColor::DPink, bDrawInForeground = true);

			for(auto Player : Game::GetPlayers())
			{
				const FVector ClosestPlayerPos = Math::ClosestPointOnLine(LaserStart, LaserEnd, Player.ActorLocation);
				LaserSoundPositions[Player.Player].SetPosition(ClosestPlayerPos);
			}

			DefaultEmitter.AudioComponent.SetMultipleSoundPositions(LaserSoundPositions);
		}
	}
}