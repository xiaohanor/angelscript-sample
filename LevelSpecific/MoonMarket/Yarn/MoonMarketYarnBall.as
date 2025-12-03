asset UMoonMarketYarnBallCapabilitySheet of UHazeCapabilitySheet
{
	Capabilities.Add(UMoonMarketYarnBallMovementCapability);
	Capabilities.Add(UMoonMarketYarnBallAirRotationCapability);
	Capabilities.Add(UMoonMarketYarnBallGroundRotationCapability);
}

struct FMoonMarketYarnBallLaunchData
{
	const UObject NewControlSide;
	FVector Impulse;
}

UCLASS(Abstract)
class AMoonMarketYarnBall : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent YarnTrail;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USphereComponent Collision;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(UMoonMarketYarnBallCapabilitySheet);

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedPositionComp;
	default SyncedPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UMovementInstigatorLogComponent MovementInstigatorLogComp;
#endif

	UPROPERTY(DefaultComponent)
	UFireworksResponseComponent FireworkResponseComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketThunderStruckComponent ThunderResponseComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketBouncyBallResponseComponent BouncyBallResponseComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketPolymorphShapeComponent ShapeComp;
	default ShapeComp.ShapeData.ShapeTag = "Yarn";
	default ShapeComp.ShapeData.bIsBubbleBlockingShape = true;
	default ShapeComp.ShapeData.bCanDash = false;
	default ShapeComp.ShapeData.bUseCustomMovement = true;
	default ShapeComp.ShapeData.bCancelByThunder = false;

	UPROPERTY()
	FRuntimeFloatCurve YarnBallScaleCurve;

	FVector AngularVelocity;

	FVector LocationLastFrame;

	UPROPERTY(EditAnywhere)
	const float TotalLength = 15000;
	
	float DistanceTraveled = 0;
	bool bEnabled = true;
	bool bWasGrounded = true;
	bool bHadWallImpact = false;

	float LastLaunchTimeByOtherPlayer = 0;

	AHazePlayerCharacter ControllingPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(IsValid(ControllingPlayer))
			SetActorControlSide(ControllingPlayer);

		LocationLastFrame = ActorLocation;
		YarnTrail.SetAbsolute(false, false, true);

		UMovementGravitySettings::SetGravityScale(this, 1.8, this);

		for(auto Player : Game::Players)
		{
			auto PlayerMoveComp = UPlayerMovementComponent::Get(Player);
			PlayerMoveComp.ApplyResolverExtension(UMoonMarketYarnBallMovementResolverExtension, this);
		}

		FireworkResponseComp.OnFireWorksImpact.AddUFunction(this, n"FireworkLaunch");
		BouncyBallResponseComp.OnHitByBallEvent.AddUFunction(this, n"HitByBouncyBall");
		ThunderResponseComp.OnStruckByThunder.AddUFunction(this, n"OnStruckByThunder");
	}

	UFUNCTION()
	private void FireworkLaunch(FMoonMarketFireworkImpactData Data)
	{
		if(ControllingPlayer != nullptr)
		{
			float UnwindedAlpha = GetYarnUnwindedAlpha();
			if(UnwindedAlpha > 0.8)
			{
				ControllingPlayer.KillPlayer();
				return;
			}
		}

		FVector Delta = ActorCenterLocation - Data.Rocket.ActorLocation;
		float DistToRocket = Delta.Size();
		float MaxImpulse = 3000;
		float Strength = Math::Clamp(MaxImpulse - DistToRocket, 0, MaxImpulse);
		FMoonMarketYarnBallLaunchData FireworkLaunchData;
		
		if(ControllingPlayer == nullptr)
			FireworkLaunchData.NewControlSide = Data.Rocket;

		FireworkLaunchData.Impulse = Delta.GetSafeNormal() * Strength;
		ApplyLaunchData(FireworkLaunchData);
	}

	UFUNCTION(CrumbFunction)
	void CrumbOnBounce()
	{
		UMoonMarketYarnBallEventHandler::Trigger_OnBounce(this);
	}

	UFUNCTION()
	private void HitByBouncyBall(FMoonMarketBouncyBallHitData Data)
	{
		if(!Data.Ball.HasControl())
			return;

		FMoonMarketYarnBallLaunchData LaunchData;
		LaunchData.NewControlSide = Data.Ball;
		LaunchData.Impulse = Data.ImpactVelocity * 0.2;
		ApplyLaunchData(LaunchData);
	}

	UFUNCTION()
	private void OnStruckByThunder(FMoonMarketThunderStruckData Data)
	{
		if(!Data.InstigatingPlayer.HasControl())
			return;

		if(ControllingPlayer != nullptr)
		{
			float UnwindedAlpha = GetYarnUnwindedAlpha();
			if(UnwindedAlpha > 0.8)
			{
				ControllingPlayer.KillPlayer();
				return;
			}
		}

		FVector HorizontalDir = (ActorCenterLocation - Data.InstigatingPlayer.ActorLocation).VectorPlaneProject(FVector::UpVector);

		if(HorizontalDir.Size() > 0)
			HorizontalDir.Normalize();

		float Impulse = 300;
		FMoonMarketYarnBallLaunchData LaunchData;
		LaunchData.NewControlSide = Data.InstigatingPlayer;
		LaunchData.Impulse = HorizontalDir * Impulse + FVector::UpVector * Impulse;
		ApplyLaunchData(LaunchData);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for(auto Player : Game::Players)
		{
			if(Player == nullptr)
				continue;

			auto PlayerMoveComp = UPlayerMovementComponent::Get(Player);
			PlayerMoveComp.ClearResolverExtension(UMoonMarketYarnBallMovementResolverExtension, this);
		}
		DestroyYarnVFX();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		DestroyYarnVFX();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bEnabled)
			return;

		DistanceTraveled += ActorLocation.Distance(LocationLastFrame);
		float NewScale = YarnBallScaleCurve.GetFloatValue(GetYarnUnwindedAlpha());

		if(Collision.SphereRadius * NewScale <= 15)
		{
			NewScale = Math::FInterpConstantTo(NewScale, 0, DeltaSeconds, 10);
		}

		if(Collision.ScaledSphereRadius <= 0.1)
		{
			bEnabled = false;
			DistanceTraveled = TotalLength;
			AddActorTickBlock(this);
			BlockCapabilities(CapabilityTags::Movement, this);
			Collision.AddComponentCollisionBlocker(this);
			Mesh.AddComponentVisualsAndCollisionAndTickBlockers(this);

			// Yarn ball is gone. So lets turn of VFX.
			DeactivateYarnVFX();
		}
		else
		{
			SetActorScale3D(FVector::OneVector * NewScale);
		}

		if(MoveComp.HasImpactedWall())
		{
			if(!bHadWallImpact)
			{
				bHadWallImpact = true;
				UMoonMarketYarnBallEventHandler::Trigger_OnHorizontalCollide(this, FMoonmarketYarnBallEventParams(MoveComp.PreviousVelocity.VectorPlaneProject(FVector::UpVector).Size()));
			}
		}
		else
		{
			bHadWallImpact = false;
		}
		
		if(MoveComp.HasImpactedGround())
		{
			if(!bWasGrounded)
			{
				bWasGrounded = true;
				UMoonMarketYarnBallEventHandler::Trigger_OnLand(this, FMoonmarketYarnBallEventParams(Math::Abs(MoveComp.PreviousVelocity.Z)));
			}
		}
		else
		{
			bWasGrounded = false;
		}

		YarnTrail.SetRelativeLocation(FVector::DownVector * (Collision.ScaledSphereRadius - 10));
		LocationLastFrame = ActorLocation;
	}

	void ApplyLaunchData(FMoonMarketYarnBallLaunchData LaunchData)
	{
 		if(IsValid(ControllingPlayer))
		{
			if(HasControl())
			{
				// We launched ourselves (?)
				// Just add the impulse
				MoveComp.AddPendingImpulse(LaunchData.Impulse);
			}
			else
			{
				if(Time::GetGameTimeSince(LastLaunchTimeByOtherPlayer) < 0.5)
					return;

				// The remote side launched the player
				// Crumb send the impulse to the player control side
				CrumbRemoteLaunchedPlayerControlledBall(LaunchData.Impulse);
			}
		}
		else
		{
			// Only allow the control side of a launch to take control
			if(!LaunchData.NewControlSide.HasControl())
				return;

			if(Time::GetGameTimeSince(LastLaunchTimeByOtherPlayer) < 0.5)
				return;

			// Crumb send the launch data and change control side to the launchers side
			CrumbLaunchAndChangeControlSide(LaunchData);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbRemoteLaunchedPlayerControlledBall(FVector Impulse)
	{
		UMoonMarketYarnBallEventHandler::Trigger_OnBounce(this);
		MoveComp.AddPendingImpulse(Impulse);
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunchAndChangeControlSide(FMoonMarketYarnBallLaunchData LaunchData)
	{
		UMoonMarketYarnBallEventHandler::Trigger_OnBounce(this);
		SetActorControlSide(LaunchData.NewControlSide);
		MoveComp.AddPendingImpulse(LaunchData.Impulse);
		LastLaunchTimeByOtherPlayer = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintPure)
	float GetYarnUnwindedAlpha() const
	{
		return Math::Saturate(DistanceTraveled / TotalLength);
	}

	void DeactivateYarnVFX()
	{
		// we've configured niagara to not spawn any more particles, but let the particles that are out in the level live.
		//  Note that this means that we need to destroy the component to get rid of the particles when we want to do that.
		auto NiagaraComps = GetComponentsByTag(UNiagaraComponent, FName(n"Yarn"));
		for(auto IterNiagaraComp : NiagaraComps)
		{
			IterNiagaraComp.Deactivate();
		}
	}

	void DestroyYarnVFX()
	{
		auto NiagaraComps = GetComponentsByTag(UNiagaraComponent, FName(n"Yarn"));
		for(auto IterNiagaraComp : NiagaraComps)
		{
			if(IterNiagaraComp != nullptr && IterNiagaraComp.IsBeingDestroyed() == false)
			{
				IterNiagaraComp.DestroyComponent(IterNiagaraComp);
			}
		}
	}

};