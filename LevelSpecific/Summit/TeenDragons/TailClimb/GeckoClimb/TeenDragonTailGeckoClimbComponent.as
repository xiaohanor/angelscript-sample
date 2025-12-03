UCLASS(Abstract)
class UTeenDragonGeckoClimbEnterWidget : UHazeUserWidget
{

}

struct FTeenDragonTailClimbParams
{
	FVector Location;
	FVector ClimbUpVector;
	FVector WallNormal;
	UTeenDragonTailClimbableComponent ClimbComp;
};

class UTeenDragonTailGeckoClimbComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UTeenDragonTailGeckoClimbSettings ClimbingSettings;	

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UTeenDragonTailGeckoClimbEnterJumpSettings EnterJumpSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UForceFeedbackEffect LeftClimbFootStepForceFeedback;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UForceFeedbackEffect RightClimbFootStepForceFeedback;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	TSubclassOf<UCameraShakeBase> ClimbFootStepCameraShake;

	AHazePlayerCharacter Player;

	UTeenDragonTailGeckoClimbOrientationComponent OrientationComp;
	FTeenDragonTailClimbParams CurrentClimbParams;
	FTeenDragonTailClimbParams WallEnterClimbParams;
	bool bHasWallEnterLocation = false;

	bool bIsGeckoJumping = false;
	bool bIsGeckoDashing = false;
	bool bGeckoDashIsCoolingDown = false;
	bool bMissedGeckoJumping = false;

	bool bIsJumpingOntoWall = false;
	bool bHasLandedOnWall = false;

	bool bIsLedgeGrabbing = false;
	bool bWantsToFall = false;

	bool bRestrictClimbToVertical = false;

	bool bWallCameraIsOn = false;
	bool bWallCameraHasTransitioned = false;

	float JumpOntoWallSpeed;
	float JumpOntoWallAlpha = 0.0;
	FRuntimeFloatCurve CurrentJumpOntoWallCurve;

	UPlayerTailTeenDragonComponent TailDragonComp;
	UTeenDragonGeckoClimbEnterWidget JumpOntoWallWidget;
	UHazeMovementComponent MoveComp;

	TArray<ATeenDragonTailGeckoClimbEdgeJumpingVolume> EdgeJumpingVolumes;
	TArray<ATeenDragonTailGeckoClimbExitVolume> ExitVolumesInside;

	TArray<USummitRollEnterWallZoneComponent> RollEnterZoneCompsCurrentlyInside;

	bool bForceRespawnOnWall = false;
	bool bWallClimbRespawnAllowed = false;
	TOptional<FTeenDragonTailClimbParams> WallClimbRespawnParams;

	float CameraTransitionAlpha = 0.0;
	float CameraTransitionAlphaTarget = 0.0;
	float CameraTransitionSpeed = 0.0;

	float TimeLastWalkedOffWall = -MAX_flt;

	// SIMON PLAYGROUND (DONT TOUCH UNLESS YOU ARE SIMON OR HAVE HIS PERMISSION :))
	const float WallEnterAnticipation = 0.1;
	const float WallEnterLandTime = 0.0;
	const float WallDashAnticipation = 0.2;
	bool bHasReachedWall = false;
	// SIMON PLAYGROUND OVER

	UPROPERTY()
	FOnTailClimbStarted OnClimbStarted;

	UPROPERTY()
	FOnTailClimbStopped OnClimbStopped;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		OrientationComp = UTeenDragonTailGeckoClimbOrientationComponent::Get(Player);
		TailDragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		Player.ApplyDefaultSettings(ClimbingSettings);
		Player.ApplyDefaultSettings(EnterJumpSettings);

		MoveComp = UHazeMovementComponent::Get(Player);

		JumpOntoWallWidget = Cast<UTeenDragonGeckoClimbEnterWidget>(Widget::CreateUserWidget(Player, EnterJumpSettings.JumpEnterWidgetClass));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!Player.IsPlayerDead())
			CameraTransitionAlpha = Math::FInterpTo(CameraTransitionAlpha, CameraTransitionAlphaTarget, DeltaSeconds, CameraTransitionSpeed);
		TEMPORAL_LOG(Owner).Value("Is Ledge Grabbing", bIsLedgeGrabbing);
	}

	void SetCameraTransitionAlphaTarget(float NewTarget, float TransitionSpeed)
	{
		CameraTransitionAlphaTarget = NewTarget;
		CameraTransitionSpeed = TransitionSpeed;
	}

	void OverrideCameraTransitionAlpha(float Alpha)
	{
		CameraTransitionAlpha = Alpha;
		CameraTransitionAlphaTarget = Alpha;
	}

	private void SetWallNormalVector(const FVector NewWallNormal)
	{
		CurrentClimbParams.WallNormal = NewWallNormal;
		OrientationComp.SetOrientationAlongWall(NewWallNormal);
	}
	
	void StartClimbing() const
	{
		CurrentClimbParams.ClimbComp.ClimbStarted(CurrentClimbParams);
		OnClimbStarted.Broadcast(CurrentClimbParams);
	}

	void StopClimbing() const
	{
		CurrentClimbParams.ClimbComp.ClimbStopped(CurrentClimbParams);
		OnClimbStopped.Broadcast(CurrentClimbParams);
	}

	void UpdateClimbParams(const FTeenDragonTailClimbParams NewParams)
	{
		/* We have a climb comp and it's not the same as the new one
		(Walking over to a new wall, or jumping to a new one) */
		if(CurrentClimbParams.ClimbComp != nullptr
		&& CurrentClimbParams.ClimbComp != NewParams.ClimbComp)
		{
			CurrentClimbParams.ClimbComp.ClimbStopped(CurrentClimbParams);
			NewParams.ClimbComp.ClimbStarted(NewParams);
		}

		CurrentClimbParams = NewParams;
		SetWallNormalVector(NewParams.WallNormal);
	}

	FVector GetClimbUpVector()
	{
		return CurrentClimbParams.ClimbUpVector;
	}

	FVector GetWallNormal()
	{
		return CurrentClimbParams.WallNormal;
	}

	FVector GetClimbLocation()
	{
		return CurrentClimbParams.Location;
	}

	bool IsOnClimbableWall()
	{
		FHazeTraceSettings Trace;
		Trace.TraceWithMovementComponent(MoveComp);

		auto HitResults = Trace.QueryTraceMulti(Player.ActorLocation,
		Player.ActorLocation -Player.ActorUpVector * ClimbingSettings.WallCheckDistance);

		for(auto HitResult : HitResults)
		{
			if(!HitResult.bBlockingHit)
				continue;

			UTeenDragonTailClimbableComponent ClimbableComp = UTeenDragonTailClimbableComponent::Get(HitResult.Actor);
			if(ClimbableComp == nullptr)
				continue;
			

			FTeenDragonTailClimbParams NewParams;
			NewParams.Location = HitResult.ImpactPoint + HitResult.ImpactNormal;
			// Debug::DrawDebugSphere(HitResult.ImpactPoint, 20);
			NewParams.WallNormal = HitResult.ImpactNormal;
			NewParams.ClimbUpVector = HitResult.Normal;
			NewParams.ClimbComp = ClimbableComp;
			
			// Debug::DrawDebugDirectionArrow(TeenDragon.ActorLocation, NewParams.ClimbUpVector, 
			// 	1000, 10, FLinearColor::Blue, 5);
			UpdateClimbParams(NewParams);
			return true;
		}
		return false;
	}

	void ToggleClimbCameraEffects(bool bToggleOn, bool bLeftSide, bool bFrontFoot, FInstigator Instigator)
	{
		if(bLeftSide)
		{
			if(bToggleOn)
			{
				Player.PlayForceFeedback(LeftClimbFootStepForceFeedback, false, true, Instigator);
				Player.PlayWorldCameraShake(ClimbFootStepCameraShake, Instigator, Player.ActorLocation - Player.ActorRightVector * 500, 0.0, 1000, 1.0, 1.0, true);
				FVector EffectLocation;
				if(bFrontFoot)
					EffectLocation = TailDragonComp.DragonMesh.GetSocketLocation(n"LeftHand");
				else
					EffectLocation = TailDragonComp.DragonMesh.GetSocketLocation(n"LeftFoot");
				FTeenDragonTailClimbOnFootSteppedInVinesParams EffectParams;
				EffectParams.Location = EffectLocation;
				EffectParams.WallNormal = GetWallNormal();
				UTeenDragonTailClimbEventHandler::Trigger_OnFootSteppedOnVine(Player, EffectParams);
			}
			else
			{
				Player.StopForceFeedback(Instigator);
				Player.StopCameraShakeByInstigator(Instigator);
			}
		}
		else
		{
			if(bToggleOn)
			{
				Player.PlayForceFeedback(RightClimbFootStepForceFeedback, false, true, Instigator);
				Player.PlayWorldCameraShake(ClimbFootStepCameraShake, Instigator, Player.ActorLocation + Player.ActorRightVector * 500, 0.0, 1000, 1.0, 1.0, true);
				FVector EffectLocation;
				if(bFrontFoot)
					EffectLocation = TailDragonComp.DragonMesh.GetSocketLocation(n"RightHand");
				else
					EffectLocation = TailDragonComp.DragonMesh.GetSocketLocation(n"RightFoot");
				FTeenDragonTailClimbOnFootSteppedInVinesParams EffectParams;
				EffectParams.Location = EffectLocation;
				EffectParams.WallNormal = GetWallNormal();
				UTeenDragonTailClimbEventHandler::Trigger_OnFootSteppedOnVine(Player, EffectParams);
			}
			else
			{
				Player.StopForceFeedback(Instigator);
				Player.StopCameraShakeByInstigator(Instigator);
			}
		}
	}
};