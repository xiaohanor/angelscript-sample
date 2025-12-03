struct FGeckoConstrainedActivationParams
{
	USkylineGeckoComponent GeckoPrime;
}

struct FGeckoConstrainedDeactivationParams
{
	bool bKill = false;	
}

class USkylineGeckoConstrainedPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"ConstrainedByGecko");
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::InfluenceMovement;

	USkylineGeckoConstrainedPlayerComponent ConstrainedComp;
	USkylineGeckoConstrainedPlayerComponent OtherConstrainedComp;
	UPlayerMovementComponent MoveComp;
	UPlayerHealthComponent HealthComp;
	UButtonMashComponent ButtonMashComp;
	USkylineGeckoSettings Settings;
	USweepingMovementData Movement;
	UPlayerHealthSettings HealthSettings; 
	USkylineGeckoComponent GeckoPrime;

	bool bActiveButtonMash = false;
	bool bIsMovementInputBlocked = false;
	bool bIsFirstTick = false;
	float DamageTime;
	float CompleteTime;
	float DamageInterval;
	float UnblockInputTime;

	FHazeLocomotionTransform RootMotion;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ConstrainedComp = USkylineGeckoConstrainedPlayerComponent::GetOrCreate(Player);	
		OtherConstrainedComp = USkylineGeckoConstrainedPlayerComponent::GetOrCreate(Player.OtherPlayer);	
		Settings = USkylineGeckoSettings::GetSettings(Player);
		HealthSettings = UPlayerHealthSettings::GetSettings(Player);
		MoveComp = UPlayerMovementComponent::Get(Player); 
		HealthComp = UPlayerHealthComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGeckoConstrainedActivationParams& OutParams) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;
		if (ConstrainedComp.ConstrainingGeckos.Num() == 0)
			return false;
		if (HealthComp.bIsDead)
			return false;
		OutParams.GeckoPrime = ConstrainedComp.ConstrainingGeckos[0];
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;
		if (ActiveDuration > CompleteTime)
			return true;
		if (ConstrainedComp.bHasRecovered)
			return true;
		if (HealthComp.bIsDead)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGeckoConstrainedActivationParams Params)
	{
		//Player.SnapToGround(true,1000);
		Player.ResetMovement(true);
		Player.HealPlayerHealth(1);

		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		UGravityBladeUserComponent BladeUserComp = UGravityBladeUserComponent::Get(Player);
		if (BladeUserComp != nullptr)
			BladeUserComp.SheatheBlade();

		bIsMovementInputBlocked = true;
		bIsFirstTick = true;
		ConstrainedComp.bHasRecovered = false;
		CompleteTime = BIG_NUMBER;
		UnblockInputTime = BIG_NUMBER;
		GeckoPrime = Params.GeckoPrime;

		// Buttonmash to shake the annoying doggos off!
		FButtonMashSettings Mash;
		Mash.Duration = Settings.ConstrainedButtonMashDuration;
		Mash.ProgressionMode = EButtonMashProgressionMode::StartFullDecayDown;
		Mash.Difficulty = Settings.ConstrainedButtonMashDifficulty;
		Mash.WidgetAttachComponent = Owner.RootComponent;
		Mash.WidgetPositionOffset = FVector(-90, 0, 25);
		ButtonMashComp = UButtonMashComponent::GetOrCreate(Player);		
		ButtonMashComp.StartButtonMash(Mash, 
									   SkylineGeckoTags::SkylineGeckoPlayerPinnedInstigatorTag, 
									   FOnButtonMashCompleted(this, n"OnButtonMashCompleted"), 
									   FOnButtonMashCompleted(), 
									   EDoubleButtonMashType::None);
		bActiveButtonMash = true;
		DamageInterval = 0.25;
		DamageTime = DamageInterval;
	
		// Neither we nor other player should be constrained again soon
		ConstrainedComp.CooldownTime = Time::GameTimeSeconds + Settings.ConstrainCooldown + Settings.ConstrainedButtonMashDuration + 1;
		OtherConstrainedComp.CooldownTime = Time::GameTimeSeconds + Settings.ConstrainCooldown + Settings.ConstrainedButtonMashDuration;

		// Pick which side is better for the camera
		UHazeCameraComponent ConstrainCamera;
		UHazeCameraComponent OtherConstrainCamera;
		for(UHazeCameraComponent Camera : GeckoPrime.ConstrainCameras)
		{
			if(ConstrainCamera == nullptr)
			{
				ConstrainCamera = Camera;
				continue;
			}

			if(Camera.WorldLocation.Distance(Player.ViewLocation) < ConstrainCamera.WorldLocation.Distance(Player.ViewLocation))
			{
				OtherConstrainCamera = ConstrainCamera;
				ConstrainCamera = Camera;
			}
			else
			{
				OtherConstrainCamera = Camera;
			}
		}

		// Trying to avoid a camera that is inside or near geometry
		FVector TraceLocationPlayer = Player.ActorLocation + (ConstrainCamera.WorldLocation - GeckoPrime.Owner.ActorLocation);
		FVector TraceLocationGecko = ConstrainCamera.WorldLocation;
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.UseSphereShape(100);
		FOverlapResultArray OverlapResultPlayer = Trace.QueryOverlaps(TraceLocationPlayer);
		FOverlapResultArray OverlapResultGecko = Trace.QueryOverlaps(TraceLocationGecko);

		if(OverlapResultPlayer.HasBlockHit() || OverlapResultGecko.HasBlockHit())
			ConstrainCamera = OtherConstrainCamera;

		Player.ActivateCamera(ConstrainCamera, 1, this);
		Player.ApplyCameraSettings(GeckoPrime.ConstrainCameraSettings, 3, this, EHazeCameraPriority::VeryHigh);
		Player.PlayCameraShake(GeckoPrime.ConstrainCameraShake, this);
		// Player.PlayForceFeedback(GeckoPrime.ConstrainForceFeedback, true, false, this);

		Player.Mesh.OnPostAnimEvalComplete.AddUFunction(this, n"OnPostAnimEvalComplete");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (bIsMovementInputBlocked)
		{
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
			Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		}
		bIsMovementInputBlocked = false;
		ConstrainedComp.bHasRecovered = true;
		Player.StopButtonMash(SkylineGeckoTags::SkylineGeckoPlayerPinnedInstigatorTag); // In case geckos were removed by outside sources
		ConstrainedComp.ConstrainingGeckos.Reset();
		if (HealthComp.bIsDead)
			ConstrainedComp.CooldownTime = Time::GameTimeSeconds + Settings.ConstrainCooldown + HealthSettings.RespawnTimer;
		else 
			ConstrainedComp.CooldownTime = Time::GameTimeSeconds + Settings.ConstrainCooldown;

		// Player.ClearPointOfInterestByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this, 3);
		Player.StopCameraShakeByInstigator(this);
		// Player.StopForceFeedback(this);
		Player.DeactivateCameraByInstigator(this);

		Player.Mesh.OnPostAnimEvalComplete.Unbind(this, n"OnPostAnimEvalComplete");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Slow to a stop and fall if in air
		if(MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				float Friction = MoveComp.HasGroundContact() ? 4.0 : 0.5;
				FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
				HorizontalVelocity *= Math::Pow(Math::Exp(-Friction), DeltaTime);
				Movement.AddHorizontalVelocity(HorizontalVelocity);
				Movement.AddVerticalVelocity(MoveComp.VerticalVelocity);
				Movement.AddGravityAcceleration();
				Movement.AddPendingImpulses();
				if (bIsFirstTick)
				{
					bIsFirstTick = false;
					AHazeActor Gecko = Cast<AHazeActor>(GeckoPrime.Owner);
					FVector ToGecko = (Gecko.ActorLocation - Owner.ActorLocation).GetSafeNormal2D();
					Movement.SetRotation(ToGecko.Rotation());
				}

				// Apply root motion
				FVector CurrentDelta = RootMotion.DeltaTranslation;
				Movement.AddDeltaWithCustomVelocity(CurrentDelta, FVector::ZeroVector);
			}
			else
			{
				if(MoveComp.HasGroundContact())
					Movement.ApplyCrumbSyncedGroundMovement();
				else
					Movement.ApplyCrumbSyncedAirMovement();
			}

			FName FeatureTag = n"ConstrainedByGecko";
			// if (MoveComp.IsInAir())
			// 	FeatureTag = n"AirMovement";
			// else if (MoveComp.HasGroundContact() && MoveComp.WasFalling())
			// 	FeatureTag = n"Landing";
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, FeatureTag);			
		}

		if (bActiveButtonMash && ActiveDuration < 0.5)
		 	ButtonMashComp.SnapButtonMashProgress(SkylineGeckoTags::SkylineGeckoPlayerPinnedInstigatorTag, 0.5);									   

		if (bActiveButtonMash && (ConstrainedComp.ConstrainingGeckos.Num() > 0) && (ActiveDuration > Settings.ConstrainedButtonMashDuration + 1.0))
		{
			// Button mash progress is decreased sharply after a while if still failing
			float MashRate;
			bool bIsSucceeding = false;
			ButtonMashComp.GetButtonMashCurrentRate(SkylineGeckoTags::SkylineGeckoPlayerPinnedInstigatorTag, MashRate, bIsSucceeding);
			if (!bIsSucceeding)
		 		ButtonMashComp.SnapButtonMashProgress(SkylineGeckoTags::SkylineGeckoPlayerPinnedInstigatorTag, ButtonMashComp.GetButtonMashProgress(SkylineGeckoTags::SkylineGeckoPlayerPinnedInstigatorTag) - (4.0 * DeltaTime / Settings.ConstrainedButtonMashDuration));
		} 

		if (HasControl() && bActiveButtonMash)
		{
			// Throw geckos off once progress has been regained
			if ((ActiveDuration > 0.5) && (ButtonMashComp.GetButtonMashProgress(SkylineGeckoTags::SkylineGeckoPlayerPinnedInstigatorTag) > 0.99))
				CrumbThrowOffGeckos(GetGeckosToThrowOff());
			// If saved by the other player, we still throw off any nearby geckos out of spite (or at least because it looks cool)
			else if (ConstrainedComp.ConstrainingGeckos.Num() == 0)
				CrumbThrowOffGeckos(GetGeckosToThrowOff());
		}

		if (HasControl())
		{
			// Check if recovery animation is ready for interruption by input
			if (ActiveDuration > UnblockInputTime && bIsMovementInputBlocked)
			{
				Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
				Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
				bIsMovementInputBlocked = false;
			}

			if (!bIsMovementInputBlocked)
			{
				FVector MovementInput;
				MovementInput = MoveComp.GetMovementInput();
				if (!MovementInput.IsNearlyZero())
					ConstrainedComp.bHasRecovered = true;
			}
		}

		if(bActiveButtonMash)
		{
			float FFFrequency = 50.0;
			float FFIntensity = 2.5;
			FHazeFrameForceFeedback FF;
			FF.LeftMotor = Math::Sin(ActiveDuration * FFFrequency) * FFIntensity;
			FF.RightMotor = Math::Sin(-ActiveDuration * FFFrequency) * FFIntensity;
			Player.SetFrameForceFeedback(FF);
		}
	}

	TArray<USkylineGeckoComponent> GetGeckosToThrowOff()
	{
		TArray<USkylineGeckoComponent> Geckos = ConstrainedComp.ConstrainingGeckos;
		if ((GeckoPrime == nullptr) && (GeckoPrime.Team == nullptr))
			return Geckos;
		FVector OwnLoc = Owner.ActorLocation;
		for (AHazeActor Gecko : GeckoPrime.Team.GetMembers())
		{
			if (Gecko == nullptr)
				continue;
			if (!Gecko.ActorLocation.IsWithinDist(OwnLoc, 200.0))
				continue;
			USkylineGeckoComponent GeckoComp = USkylineGeckoComponent::Get(Gecko);
			if (GeckoComp == nullptr)
				continue;
			Geckos.AddUnique(GeckoComp);
		}
		return Geckos;	
	}

	UFUNCTION()
	private void OnButtonMashCompleted()
	{
		// Buttonmash will complete when progress falls to 0. 
		bActiveButtonMash  = false;

		// Deal fatal damage to player (so we'll survive in jesus mode etc)
		Player.DealTypedDamage(GeckoPrime.Character, 1.0, EDamageEffectType::ObjectSmall, EDeathEffectType::ObjectSmall);
		CompleteTime = 0.0;

		// This is broadcast on both sides in network
		ConstrainedComp.ConstrainingGeckos.Reset();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbThrowOffGeckos(TArray<USkylineGeckoComponent> Geckos)
	{
		// Button mash suceeded, throw doggos off
		bActiveButtonMash = false;
		ButtonMashComp.StopButtonMash(SkylineGeckoTags::SkylineGeckoPlayerPinnedInstigatorTag);
		for (USkylineGeckoComponent GeckoComp : Geckos)
		{
			GeckoComp.bThrownOff = true;
			GeckoComp.ThrownOffDirection = Player.ViewRotation.ForwardVector.GetSafeNormal2D();
		}
		ConstrainedComp.ConstrainingGeckos.Reset();

		// Recover
		float RecoverTime = 1.0;
		ULocomotionFeatureConstrainedByGecko Feature = Player.Mesh.GetFeatureByClass(ULocomotionFeatureConstrainedByGecko);
		if (Feature != nullptr)
			RecoverTime = Feature.AnimData.Constrained_Recover.Sequence.ScaledPlayLength - 0.2;
		CompleteTime = ActiveDuration + RecoverTime;
		UnblockInputTime = ActiveDuration + Settings.ConstrainedInputUnblockRecoverTime;

		Player.HealPlayerHealth(1);
		Timer::SetTimer(this,n"ClearConstrainPoiTimer",0.5f,false,0,0);

		Player.DeactivateCameraByInstigator(this);
	}

	UFUNCTION()
	private void ClearConstrainPoiTimer()
	{
		// Player.ClearPointOfInterestByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this, 3);
		Player.StopCameraShakeByInstigator(this);
		// Player.StopForceFeedback(this);
	}

	UFUNCTION()
	private void OnPostAnimEvalComplete(UHazeSkeletalMeshComponentBase SkeletalMesh)
	{
		SkeletalMesh.ConsumeLastExtractedRootMotion(RootMotion);
	}
}



class USkylineGeckoConstrainedPlayerComponent : UActorComponent
{
	float CooldownTime = 0.0;
	TArray<USkylineGeckoComponent> ConstrainingGeckos;
	bool bIntialCooldown;
	bool bHasRecovered = false;
	int ConstrainNum;

	void InitialConstrainCooldown()
	{
		if(bIntialCooldown)
			return;
		bIntialCooldown = true;
		UGentlemanComponent::Get(Owner).ClaimToken(n"ConstrainToken", Owner);
		if(Cast<AHazePlayerCharacter>(Owner).IsMio())
			UGentlemanComponent::Get(Owner).ReleaseToken(n"ConstrainToken", Owner, Math::RandRange(2, 3));
		else 
			UGentlemanComponent::Get(Owner).ReleaseToken(n"ConstrainToken", Owner, Math::RandRange(10, 12));
	}

	bool CanConstrain() const
	{
		if (ConstrainingGeckos.Num() > 0)
			return false; // One at a time please!
		if (Time::GameTimeSeconds < CooldownTime)
			return false; // Not past cooldown yet
		return true;
	}

	bool IsConstrained() const
	{
		if (ConstrainingGeckos.Num() > 0)
			return true;
		return false;
	}

	bool IsConstrainedBy(USkylineGeckoComponent GeckoComp)
	{
		return ConstrainingGeckos.Contains(GeckoComp);
	}

	void Constrain(USkylineGeckoComponent GeckoComp)
	{
		ConstrainingGeckos.AddUnique(GeckoComp);
	}
}

namespace GeckoConstrainingPlayer
{
	void StopConstraining(USkylineGeckoComponent GeckoComp)
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			auto ConstrainComp = USkylineGeckoConstrainedPlayerComponent::Get(Player);
			if (ConstrainComp != nullptr)
				ConstrainComp.ConstrainingGeckos.RemoveSingleSwap(GeckoComp);
		}
	}
}
