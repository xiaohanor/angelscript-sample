asset TeenDragonMovementSettingsPersimmonAutoTargetOverride of UTeenDragonMovementSettings
{
	AirHorizontalVelocityAccelerationWithInput = 0.0;
	AirHorizontalVelocityAccelerationWithoutInput = 0.0;
}

asset TeenDragonRollSettingsPersimmonAutoTargetOverride of UTeenDragonRollSettings
{
	MinimumRollSpeed = 0.0;
	RollSidewaysMaxSpeed = 0.0;
	RollAirTurnRate = 0.0;
}

event void FSummitDarkCaveBouncyPersimmonEvent();

class ASummitDarkCaveBouncyPersimmon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PersimmonMesh;
	default PersimmonMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent CollisionMesh;
	default CollisionMesh.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 60000.0;

	UPROPERTY(DefaultComponent)
	USceneComponent AutoAimTarget;

	UPROPERTY(DefaultComponent)
	UTeenDragonRollNonBouncableComponent NonBounceComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	USummitDarkCaveBouncyPersimmonDummyComponent DummyComp;
#endif

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ImpulseSizeTailDragon = 3000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ImpulseSizeAcidDragon = 3500.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ForwardImpulseSize = 1250.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float AcidForwardImpulseMultiplier = 1.0;
	
	UPROPERTY(EditAnywhere, Category = "Settings")
	float TailForwardImpulseMultiplier = 1.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ScaleDownDuration = 0.055;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector BouncingScaleMultiplier = FVector(2.0, 2.0, 0.5);

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bAutoAimTowardsTarget = false;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = bAutoAimTowardsTarget, EditConditionHides))
	float AutoAimImpulseHeight = 2000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float LaunchDelay = 0.1;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float LaunchVerticalSpeedThreshold = 50.0;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AActor BranchToImpulseWhenLanded = nullptr;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	APreDarkCavePersimonBacktrackManager PreDarkCavePersimonBacktrackManager;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AActor AlternativeBranchToImpulseWhenLanded = nullptr;

	UPROPERTY(EditInstanceOnly, Category = "Setup", Meta = (EditCondition = "BranchToImpulseWhenLanded != nullptr", EditConditionHides))	
	FRotator BranchImpulseAxis = FRotator(1.0, 0, 0.0);

	UPROPERTY(EditInstanceOnly, Category = "Setup", Meta = (EditCondition = "BranchToImpulseWhenLanded != nullptr", EditConditionHides))	
	float BranchImpulseSize = 30.0;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UForceFeedbackEffect Rumble;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	TSubclassOf<UCameraShakeBase> CameraShake;

	FSummitDarkCaveBouncyPersimmonEvent OnPlayerLandedOnPersimmon;

	float PlayerLastImpacted = -MAX_flt;
	float PlayerLastImpactedWithLowVelocity = -MAX_flt;
	FVector InitialMeshScale;
	float InitialCollisionZScale;

	FHazeAcceleratedVector AccMeshScale;
	FHazeAcceleratedRotator AccBranchRotation;
	FRotator BranchStartRotation;

	TPerPlayer<bool> AutoAimSettingsOverriden;
	TPerPlayer<bool> IsOnPersimmon;
	TPerPlayer<float> AutoAimSettingsOverrideTime;
	TPerPlayer<UPlayerMovementComponent> MoveComp;
	TPerPlayer<UPlayerTeenDragonComponent> DragonComp;
 
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnPlayerImpacted");
		MovementImpactComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"OnPlayerStoppedImpacting");
		InitialMeshScale = PersimmonMesh.WorldScale;
		InitialCollisionZScale = CollisionMesh.WorldScale.Z;

		for(auto Player : Game::Players)
		{
			AutoAimSettingsOverriden[Player] = false;
			IsOnPersimmon[Player] = false;
			MoveComp[Player] = UPlayerMovementComponent::Get(Player);
		}

		if(BranchToImpulseWhenLanded != nullptr)
		{
			BranchToImpulseWhenLanded.RootComponent.SetMobility(EComponentMobility::Movable);
			if(BranchToImpulseWhenLanded.AttachParentActor == this)
				BranchToImpulseWhenLanded.DetachFromActor(EDetachmentRule::KeepWorld);
			AttachToActor(BranchToImpulseWhenLanded, AttachmentRule = EAttachmentRule::KeepWorld);
			BranchStartRotation = BranchToImpulseWhenLanded.ActorRotation;
			AccBranchRotation.SnapTo(BranchStartRotation);
		}

		if (AlternativeBranchToImpulseWhenLanded != nullptr)
		{
			AlternativeBranchToImpulseWhenLanded.AddActorDisable(this);
		}

		AccMeshScale.SnapTo(InitialMeshScale);

		if (PreDarkCavePersimonBacktrackManager != nullptr)
			PreDarkCavePersimonBacktrackManager.SetOffset();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!IsBeforeLaunchDelay())
		{
			for(auto Player : Game::Players)
			{
				if(IsOnPersimmon[Player])
					LaunchPlayer(Player);
			}
		}

		FVector TargetScale;
		if(Time::GetGameTimeSince(PlayerLastImpacted) < ScaleDownDuration)
			TargetScale = InitialMeshScale * BouncingScaleMultiplier;
		else
			TargetScale = InitialMeshScale;
		AccMeshScale.SpringTo(TargetScale, 100, 0.1, DeltaSeconds);
		PersimmonMesh.SetWorldScale3D(AccMeshScale.Value);

		const float CurrentMeshScaleZFraction = AccMeshScale.Value.Z / InitialMeshScale.Z;
		FVector CollisionScale = CollisionMesh.WorldScale;
		CollisionScale.Z = CurrentMeshScaleZFraction * InitialCollisionZScale;
		CollisionMesh.SetWorldScale3D(CollisionScale);

		for(auto Player : Game::Players)
		{
			if(AutoAimSettingsOverriden[Player]
			&& MoveComp[Player].IsOnAnyGround() && Time::GetGameTimeSince(AutoAimSettingsOverrideTime[Player]) > 0.2)
			{
				Player.ClearSettingsByInstigator(this);
			}

			if(DragonComp[Player] == nullptr)
				DragonComp[Player] = UPlayerTeenDragonComponent::Get(Player);
			
			if(IsOnPersimmon[Player])
			{
				TEMPORAL_LOG(Player, "Bouncy Persimmon")
					.Value("Is On Persimmon", IsOnPersimmon[Player])
				;	
			}
			if(AutoAimSettingsOverriden[Player])
			{
				TEMPORAL_LOG(Player, "Bouncy Persimmon")
					.Value("Auto Aim Settings Overridden", AutoAimSettingsOverriden[Player])
				;	
			}
		}

		if(BranchToImpulseWhenLanded != nullptr)
		{
			AccBranchRotation.SpringTo(BranchStartRotation, 30, 0.3, DeltaSeconds);
			BranchToImpulseWhenLanded.SetActorRotation(AccBranchRotation.Value);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerImpacted(AHazePlayerCharacter Player)
	{
		if(MoveComp[Player].PreviousVerticalVelocity.Size() < LaunchVerticalSpeedThreshold)
		{
			if(Time::GetGameTimeSince(PlayerLastImpactedWithLowVelocity) < 0.5)
				return;

			AccMeshScale.Velocity += FVector(3.5, 3.5, -3.5);
			PlayerLastImpactedWithLowVelocity = Time::GameTimeSeconds;
			return;
		}

		Player.PlayForceFeedback(Rumble, false, true, this);
		Player.PlayCameraShake(CameraShake, this);

		auto RollComp = UTeenDragonRollComponent::Get(Player);
		if(RollComp != nullptr
		&& RollComp.IsRolling())
			LaunchPlayer(Player);
		if(!IsBeforeLaunchDelay())
			PlayerLastImpacted = Time::GameTimeSeconds;
		IsOnPersimmon[Player] = true;
		OnPlayerLandedOnPersimmon.Broadcast();

		MoveComp[Player].FollowComponentMovement(CollisionMesh, this);

		if(BranchToImpulseWhenLanded != nullptr)
		{
			FRotator AngularImpulse = BranchImpulseAxis * -BranchImpulseSize;
			AccBranchRotation.Velocity += AngularImpulse;
		}

		FSummitDarkCaveBouncyPersimmonOnLandedParams LandParams;
		LandParams.LandLocation = Player.ActorLocation;
		USummitDarkCaveBouncyPersimmonEventHandler::Trigger_OnLandedOnPersimmon(this, LandParams);
		TEMPORAL_LOG(Player, "Bouncy Persimmon")
			.Event("Started Impacting")
			.Value("Is Before Launch Delay", IsBeforeLaunchDelay())
		;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerStoppedImpacting(AHazePlayerCharacter Player)
	{
		if(IsOnPersimmon[Player]
		&& IsBeforeLaunchDelay())
			LaunchPlayer(Player);
		DragonComp[Player].ConsumeJumpInput();
		DragonComp[Player].bJumpInputConsumed = false;
		IsOnPersimmon[Player] = false;

		MoveComp[Player].UnFollowComponentMovement(this);
		
		TEMPORAL_LOG(Player, "Bouncy Persimmon")
			.Event("Stopped Impacting")
			.Value("Is Before Launch Delay", IsBeforeLaunchDelay())
		;
	}

	private void LaunchPlayer(AHazePlayerCharacter Player)
	{
 		FVector Impulse;
		bool bIsGoingTowardsAutoAim = true;
		FName ImpulseName = NAME_None;

		if(bAutoAimTowardsTarget)
		{
			FVector DirToAutoAim = (AutoAimTarget.WorldLocation - Player.ActorLocation).GetSafeNormal();
			bIsGoingTowardsAutoAim = Player.ActorHorizontalVelocity.DotProduct(DirToAutoAim) > 0.5;			

			if(bIsGoingTowardsAutoAim)
			{
				auto GravitySettings = UMovementGravitySettings::GetSettings(Player);
				float GravityMagnitude = GravitySettings.GravityAmount * GravitySettings.GravityScale;
				Impulse = Trajectory::CalculateVelocityForPathWithHeight(Player.ActorLocation, AutoAimTarget.WorldLocation, GravityMagnitude, AutoAimImpulseHeight);
				Player.ActorVelocity = FVector::ZeroVector;
				Player.ApplySettings(TeenDragonMovementSettingsPersimmonAutoTargetOverride, this, EHazeSettingsPriority::Override);
				Player.ApplySettings(TeenDragonRollSettingsPersimmonAutoTargetOverride, this, EHazeSettingsPriority::Override);
				AutoAimSettingsOverriden[Player] = true;
				AutoAimSettingsOverrideTime[Player] = Time::GameTimeSeconds;
				ImpulseName = TeenDragonCapabilityTags::TeenDragonRollImpulseBlockAirControl;
			}
		}

		if(!bAutoAimTowardsTarget
		|| !bIsGoingTowardsAutoAim)
		{
			float ImpulseSize = Player.IsMio() ? ImpulseSizeAcidDragon : ImpulseSizeTailDragon;
			float UpwardsSpeed = MoveComp[Player].Velocity.DotProduct(MoveComp[Player].WorldUp);
			UpwardsSpeed = Math::Max(UpwardsSpeed, 0);
			if(UpwardsSpeed > 0)
				ImpulseSize -= UpwardsSpeed;
			FVector UpImpulse = Player.ActorUpVector * ImpulseSize;
			FVector ForwardImpulse = Player.ActorForwardVector * ForwardImpulseSize;
			ForwardImpulse *= Player.IsMio() ? AcidForwardImpulseMultiplier : TailForwardImpulseMultiplier;
			
			TEMPORAL_LOG(Player, "Bouncy Persimmon")
				.DirectionalArrow("Up Impulse", Player.ActorLocation, UpImpulse, 5, 40, FLinearColor::White)
				.DirectionalArrow("Forward Impulse", Player.ActorLocation, ForwardImpulse, 5, 40, FLinearColor::Black)
				.Value("Upwards Speed Before Launch", UpwardsSpeed)
			;
			Impulse = UpImpulse + ForwardImpulse;
		}

		FSummitDarkCaveBouncyPersimmonOnLaunchedParams LaunchParams;
		LaunchParams.LaunchVelocity = Impulse;
		LaunchParams.LaunchedPlayer = Player;
		USummitDarkCaveBouncyPersimmonEventHandler::Trigger_OnLaunchedPlayer(this, LaunchParams);

		Player.AddMovementImpulse(Impulse, ImpulseName);
		IsOnPersimmon[Player] = false;
	}

	private bool IsBeforeLaunchDelay() const
	{
		return Time::GetGameTimeSince(PlayerLastImpacted) <= LaunchDelay;
	}

	UFUNCTION()
	void SetPostDentistState()
	{
		CollisionMesh.SetHiddenInGame(false);
		PersimmonMesh.SetHiddenInGame(true);
	}

	UFUNCTION()
	void SwapVisibilityToAlternativeBranch()
	{
		if (BranchToImpulseWhenLanded != nullptr && AlternativeBranchToImpulseWhenLanded != nullptr)
		{
			BranchToImpulseWhenLanded.AddActorDisable(this);
			AlternativeBranchToImpulseWhenLanded.RemoveActorDisable(this);
		}
	}
};


#if EDITOR
class USummitDarkCaveBouncyPersimmonDummyComponent : UActorComponent {};
class USummitDarkCaveBouncyPersimmonComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitDarkCaveBouncyPersimmonDummyComponent;
	
	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USummitDarkCaveBouncyPersimmonDummyComponent>(Component);
		if(Comp == nullptr)
			return;
		auto Persimmon = Cast<ASummitDarkCaveBouncyPersimmon>(Comp.Owner);
		if(Persimmon == nullptr)
			return;
		
		if(Persimmon.bAutoAimTowardsTarget)
		{
			DrawWireSphere(Persimmon.AutoAimTarget.WorldLocation, 200, FLinearColor::Green, 10, 24, false);
		}

		if(Persimmon.BranchToImpulseWhenLanded != nullptr)
		{
			auto Branch = Persimmon.BranchToImpulseWhenLanded;
			DrawWireSphere(Branch.ActorLocation, 100, FLinearColor::Blue, 20);

			if(Persimmon.BranchImpulseAxis.Pitch > 0)
			{
				FVector Direction = Branch.ActorRotation.ForwardVector;
				DrawArc(Branch.ActorLocation, 45, 1500, Direction, FLinearColor::Red, 20, Branch.ActorRightVector, 32, 100, true);
			}
			else if(Persimmon.BranchImpulseAxis.Roll > 0)
			{
				FVector Direction = Branch.ActorRotation.RightVector;
				DrawArc(Branch.ActorLocation, 45, 1500, Direction, FLinearColor::Green, 20, Branch.ActorForwardVector, 32, 100, true);
			}
			else if(Persimmon.BranchImpulseAxis.Yaw > 0)
			{
				FVector Direction = Branch.ActorRotation.UpVector;
				DrawArc(Branch.ActorLocation, 45, 1500, Direction, FLinearColor::Blue, 20, Branch.ActorRightVector, 32, 100, true);
			}
		}
	}
}
#endif