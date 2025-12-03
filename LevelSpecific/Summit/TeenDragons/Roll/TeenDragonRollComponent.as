class UTeenDragonRollComponent : UActorComponent
{
	UPROPERTY(Category = "Haptic Feedback")
	UForceFeedbackEffect RollJumpRumble;

	UPROPERTY(Category = "Haptic Feedback")
	UForceFeedbackEffect RollWallKnockBackRumble;

	UPROPERTY(Category = "Haptic Feedback")
	UForceFeedbackEffect RollReflectOffWallRumble;

	UPROPERTY(Category = "Haptic Feedback")
	UForceFeedbackEffect RollStartRumble;
	
	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> RollWallKnockBackCameraShake;

	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> RollReflectOffWallCameraShake;

	TArray<FInstigator> RollingInstigators;
	TArray<FInstigator> RollUntilImpactInstigators;
	TArray<FInstigator> ForceRollInstigators;
	TArray<FInstigator> BlockKnockBackInstigators;

	TArray<USummitRollLaunchToPointZoneComponent> RollLaunchToPointZonesInside;

	bool bHasBeenLaunched = false;
	bool bRollIsStarted = false;
	bool bHasLandedBetweenHomingAttacks = false;
	bool bSteeringIsOverridenByAutoAim = false;

	float TimeLastStartedRoll = -MAX_flt;
	float TimeLastReflectedOffWall = -MAX_flt;
	float TimeLastBecameAirborne = -MAX_flt;
	
	TOptional<FTeenDragonRollWallKnockbackParams> KnockbackParams;
	TOptional<USummitRollKnockBackToPointZoneComponent> OverriddenKnockBackComponent;

	TOptional<FTeenDragonRollReflectOffWallData> ReflectOffWallData;

	bool bIsHomingTowardsTarget = false;
	UTeenDragonRollAutoAimComponent AttackTarget;
	UPlayerTeenDragonComponent DragonComp;
	UPlayerMovementComponent MoveComp;

	FVector PreviousMovementInput;

	AHazePlayerCharacter Player;

	private UTeenDragonRollSettings RollSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);

		RollSettings = UTeenDragonRollSettings::GetSettings(Player);
	}

	bool IsRolling() const	
	{
		TEMPORAL_LOG(Player, "Teen Dragon Roll")
			.Value("Is Rolling", RollingInstigators.Num() > 0)
		;
		return RollingInstigators.Num() > 0;
	}

	bool IsForcedRolling() const
	{
		TEMPORAL_LOG(Player, "Teen Dragon Roll")
			.Value("Is Forced Rolling", ForceRollInstigators.Num() > 0 || RollUntilImpactInstigators.Num() > 0)
		;
		return ForceRollInstigators.Num() > 0 || RollUntilImpactInstigators.Num() > 0;
	}

	bool KnockBackIsBlocked() const
	{
		TEMPORAL_LOG(Player, "Teen Dragon Roll")
			.Value("Knockback Is Blocked" , BlockKnockBackInstigators.Num() > 0)
		;
		return BlockKnockBackInstigators.Num() > 0;
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	void CrumbSendRollHits(TArray<FTeenDragonRollResolverResponseComponentHitData> ImpactData)
	{
		int ImpactsRegistered = 0;
		for(auto Data : ImpactData)
		{
			Data.ResponseComp.ActivateRollHit(Data.RollParams);
			UTeenDragonRollEventHandler::Trigger_RollImpact(Player, Data.RollParams);
			UTeenDragonRollEventHandler::Trigger_RollImpact(Cast<AHazeActor>(DragonComp.DragonMesh.Owner), Data.RollParams);
			auto TempLogPage = TEMPORAL_LOG(Player, "Teen Dragon Roll")
				.Page(f"Response Comp: {Data.ResponseComp} {ImpactsRegistered}")
					.Sphere("Impact Location", Data.RollParams.HitLocation, 200, FLinearColor::Red, 10)
					.Value("Speed At Hit", Data.RollParams.SpeedAtHit)
					.Value("Speed towards Impact", Data.RollParams.SpeedTowardsImpact)
					.DirectionalArrow("Impact Normal", Data.RollParams.HitLocation, Data.RollParams.WallNormal * 500, 10, 400, FLinearColor::Blue)
					.DirectionalArrow("Roll direction", Player.ActorCenterLocation, Data.RollParams.RollDirection * 500, 10, 400, FLinearColor::Red)
					.Value("Hit Primitive", Data.RollParams.HitComponent)
					.Value("Owner", Data.ResponseComp.Owner)
			;
			ImpactsRegistered++;
		}
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	void CrumbSendRollWallKnockback(FRollParams ImpactParams)
	{
		UTeenDragonRollEventHandler::Trigger_RollImpact(Cast<AHazeActor>(DragonComp.DragonMesh.Owner), ImpactParams);
		FTeenDragonRollOnKnockedBackFromWallParams Params;
		Params.WallHitLocation = ImpactParams.HitLocation;
		Params.WallNormal = ImpactParams.WallNormal;
		Params.SpeedIntoWall = ImpactParams.SpeedTowardsImpact;
		UTeenDragonRollVFX::Trigger_OnKnockedBackFromWall(Player, Params);
	}
	
	bool ShouldStartHoming(const bool bRequireJump) const
	{
		if(!MoveComp.IsInAir())
			return false;
		
		if(bRequireJump)
		{
			if(!DragonComp.bIsInAirFromJumping)
				return false;
		}

		if(!bHasLandedBetweenHomingAttacks)
			return false;

		return true;
	}

	void ApplyRollHaptic(float RollSpeed)
	{
		FHazeFrameForceFeedback ForceFeedBack;

		float SpeedAlpha = Math::GetPercentageBetweenClamped(0, RollSettings.MaximumRollSpeed, RollSpeed);
		float BaseValue = 0.015;

		float Frequency = 20 * SpeedAlpha;
		float SpeedMagnitudeModifier = SpeedAlpha * 3.0;
		float NoiseBased = (0.025 * SpeedMagnitudeModifier) *  ((Math::Cos(Time::GameTimeSeconds * Frequency) + 1.0) * 0.5);
		
		float MotorStrength = NoiseBased + BaseValue;

		// ForceFeedBack.RightTrigger = MotorStrength;
		ForceFeedBack.RightMotor = MotorStrength * 0.15;
		ForceFeedBack.LeftMotor = MotorStrength * 0.15;
		Player.SetFrameForceFeedback(ForceFeedBack);
	}
};