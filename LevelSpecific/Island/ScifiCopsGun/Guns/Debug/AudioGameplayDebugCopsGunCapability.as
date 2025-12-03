enum EAudioDebugCopsGunMode
{
	Tracking,
	Targeted,
	SweepingStraight,
	SweepingSideways,
}

class UAudioGameplayDebugCopsGunCapability : UAudioGameplayDebugCapabilityBase
{
	AHazePlayerCharacter PlayerOwner;
	AScifiCopsGun LeftGun;
	AScifiCopsGun RightGun;

	EAudioDebugCopsGunMode DebugMode = EAudioDebugCopsGunMode::SweepingStraight;
	bool bFacePlayer = true;

	float FireRate = 0.1;
	float TargetOffset = 350.0;
	float SweepSpeed = 2.0;
	float SweepLength = 250.0;

	private float SweepDelta = 0.0;

	EHazePlayer Target = EHazePlayer::Mio;

	FVector ForcedTargetLocation;
	FVector ToTarget;
	FVector LockedTargetLocation;

	bool bHasTargetLocation = false;

	UScifiPlayerCopsGunManagerComponent Manager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		if(PlayerOwner == Game::GetZoe())
			return;

		Manager = UScifiPlayerCopsGunManagerComponent::Get(Owner);
		Manager.EnsureWeaponSpawn(PlayerOwner, LeftGun, RightGun);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerOwner == Game::GetZoe())
			return false;

		if(Manager.WeaponsAreAttachedToPlayerHand())
			return false;

		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Manager.WeaponsAreAttachedToPlayerHand())
			return true;

		return Super::ShouldDeactivate();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		ProcessGunDebug(DeltaSeconds, LeftGun);
		ProcessGunDebug(DeltaSeconds, RightGun);
	}

	void ProcessGunDebug(float DeltaSeconds, AScifiCopsGun& Gun)
	{
		// Set Fire rate
		Gun.Settings.CooldownBetweenBullets = FireRate;
		Gun.Settings.CooldownBetweenBullets = FireRate;

		// Get TargetPlayer
		AHazePlayerCharacter TargetPlayer;
		if(Target == EHazePlayer::Mio)
			TargetPlayer = Game::GetMio();
		else
			TargetPlayer = Game::GetZoe();

		// Set rotation based on DebugMode

		// Rotation is actually inverted		
		FRotator GunRotation; 

		if(DebugMode != EAudioDebugCopsGunMode::Targeted)
		{
			bHasTargetLocation = false;

			ToTarget = Gun.GetActorLocation() - TargetPlayer.GetActorLocation();
			switch(DebugMode)
			{
				case(EAudioDebugCopsGunMode::Tracking):
				{
					float RandX = Math::RandRange(-TargetOffset, TargetOffset);
					float RandY = Math::RandRange(-TargetOffset, TargetOffset);

					ToTarget.X += RandX;
					ToTarget.Y += RandY;
					break;
				}
				case(EAudioDebugCopsGunMode::SweepingStraight):
				{
					SweepDelta += DeltaSeconds;
					float Sine = Math::Sin(SweepDelta * SweepSpeed);
					
					float SweepMovement = Sine * SweepLength;
					ToTarget.X +=SweepMovement;
					break;
				}
				case(EAudioDebugCopsGunMode::SweepingSideways):
				{
					SweepDelta += DeltaSeconds;
					float Sine = Math::Sin(SweepDelta * SweepSpeed);
					
					float SweepMovement = Sine * SweepLength;
					ToTarget.Y +=SweepMovement;
					break;
				}
				default: break;
			}
			
		}
		else
		{
			ToTarget = Gun.GetActorLocation() - ForcedTargetLocation;

			if(WasActionStartedDuringTime(ActionNames::Cancel, 0.01))
			{
				ForcedTargetLocation = TargetPlayer.GetActorLocation();
				bHasTargetLocation = true;
			}
		}

		float RandX = Math::RandRange(-TargetOffset, TargetOffset);
		float RandY = Math::RandRange(-TargetOffset, TargetOffset);

		ToTarget.X += RandX;
		ToTarget.Y += RandY;

		const float FaceDirectionMultiplier = bFacePlayer ? 1.0 : -1.0;
		ToTarget *= FaceDirectionMultiplier;

		GunRotation = ToTarget.ToOrientationRotator();
		Gun.SetActorRotation(GunRotation);

		if(Gun.IsLeftWeapon())
		{
			PrintToScreenScaled(""+DebugMode, Scale = 2.0);
			if(bHasTargetLocation)
				Debug::DrawDebugSphere(ForcedTargetLocation, LineColor = FLinearColor::Green);
		}
	}
}