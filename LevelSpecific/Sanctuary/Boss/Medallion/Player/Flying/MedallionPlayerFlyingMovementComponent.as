class UMedallionPlayerFlyingMovementComponent : UActorComponent
{
	UHazeCrumbSyncedFloatComponent SyncedUpwards;
	UHazeCrumbSyncedFloatComponent SyncedSideways;
	FHazeAcceleratedFloat AccDashAlpha;
	FHazeAcceleratedFloat AccKnockedAlpha;
	FHazeAcceleratedFloat AccKnockedIntoScreen;
	float KnockedDirectionSign = 0.0;
	float BarrelRollAlpha;
	bool bBarrelRollClockwise = true;
	float KnockRotationAlpha;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SyncedUpwards = UHazeCrumbSyncedFloatComponent::Create(Player, n"Player_HydraBoss_SyncedUpwards");
		SyncedUpwards.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		SyncedSideways = UHazeCrumbSyncedFloatComponent::Create(Player, n"Player_HydraBoss_SyncedSideways");
		SyncedSideways.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AccDashAlpha.AccelerateToWithStop(0.0, MedallionConstants::Flying::DashDuration, DeltaSeconds, 0.01);
		BarrelRollAlpha -= DeltaSeconds / MedallionConstants::Flying::BarrelRollDuration;
		BarrelRollAlpha = Math::Saturate(BarrelRollAlpha);

		AccKnockedAlpha.AccelerateToWithStop(0.0, MedallionConstants::Flying::KnockedDuration, DeltaSeconds, 0.01);
		KnockRotationAlpha -= DeltaSeconds / MedallionConstants::Flying::KnockRotationDuration;
		KnockRotationAlpha = Math::Saturate(KnockRotationAlpha);

		AccKnockedIntoScreen.SpringTo(0.0, 50, 0.8, DeltaSeconds);
		//AccKnockedIntoScreen.AccelerateTo(0.0, 5.0, DeltaSeconds);
		
		// if (AccDashAlpha.Value > KINDA_SMALL_NUMBER)
		// 	Debug::DrawDebugString(Owner.ActorLocation, "DASHING");
	}
};