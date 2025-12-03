struct FCentipedeWaterSpoutData
{
	FVector StartLocation;
	FVector EndLocation;
	float InterpolationTimer = 0.0;
}

class ACentipedeWaterOutlet : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCentipedeBiteResponseComponent BiteResponseComp;

	UPROPERTY(DefaultComponent, Attach = BiteResponseComp)
	UArrowComponent TargetTransformComp;

	UPROPERTY(DefaultComponent, Attach = BiteResponseComp)
	UNiagaraComponent OutletVFXComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SprayVFXComp;

	UPROPERTY(DefaultComponent, Attach = SprayVFXComp)
	UHazeCapsuleCollisionComponent WaterTriggerComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComponent;

	UPROPERTY(Category = ForceFeedback)
	UForceFeedbackEffect BiteStartForceFeedbackEffect;

	UPROPERTY(Category = ForceFeedback)
	UForceFeedbackEffect PulsingForceFeedbackEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ACentipedeWaterPlug> WaterPlugClass;

	UPROPERTY()
	float WaterImpactForwardsOffset = 500.0;

	UPROPERTY()
	float WaterStartDistance = 150.0;

	UPROPERTY()
	float WaterEndDistance = 1400.0;

	UPROPERTY()
	float WaterLifetime = 1.0;

	UPROPERTY(EditAnywhere)
	float LetGoPushMagnitude = 2000.0;

	AHazePlayerCharacter BitePlayer;
	AHazePlayerCharacter SprayPlayer;

	FHazeAcceleratedFloat WaterImpactOffset;

	TArray<FCentipedeWaterSpoutData> WaterSpouts;

	UPROPERTY(EditInstanceOnly)
	bool bBlockedByRubble = false;

	float CapsuleHalfHeight;

	float SpoutCooldown = 0.0;
	float SpoutInterval = 0.1;

	int ReservedSpouts = 32;
	bool bSpouting = false;
	bool bWaterLeft = true;
	bool bPlugged = false;
	float DevToggleReplugTimer = 1.0;
	int SpawnedPlugs = 0;

	FVector SpoutDirection;
	FHazeAcceleratedFloat AccVelocityWeight;

	FVector LastSpoutyDirection;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BiteResponseComp.OnCentipedeBiteStarted.AddUFunction(this, n"HandleBiteStarted");
		BiteResponseComp.OnCentipedeBiteStopped.AddUFunction(this, n"HandleBiteStopped");

		CapsuleHalfHeight = WaterTriggerComp.CapsuleHalfHeight;
		WaterSpouts.Reserve(ReservedSpouts);

		SanctuaryCentipedeDevToggles::Draw::WaterThings.MakeVisible();

		if (WaterPlugClass != nullptr && !bBlockedByRubble)
			SpawnPlug();
		if (bBlockedByRubble)
			Plugged();
	}

	private void SpawnPlug()
	{
		auto WaterPlug = SpawnActor(WaterPlugClass, ActorLocation, ActorRotation, NAME_None, true);
		WaterPlug.MakeNetworked(this, SpawnedPlugs);
		SpawnedPlugs++;
		FinishSpawningActor(WaterPlug);
		WaterPlug.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
		WaterPlug.OnUnplugged.AddUFunction(this, n"Unplugged");
		Plugged();
	}

	private void Plugged()
	{
		BiteResponseComp.SetUsableByPlayers(EHazeSelectPlayer::None);
		OutletVFXComp.Deactivate();
		bPlugged = true;
	}

	UFUNCTION()
	void Unplugged(AHazePlayerCharacter BitingPlayer)
	{
		BiteResponseComp.SetUsableByPlayers(EHazeSelectPlayer::Both);
		OutletVFXComp.Activate();
		bPlugged = false;
		DevToggleReplugTimer = 1.0;
		FCentipedeWaterOutletUnplugEventParams Data;
		Data.BitingPlayer = BitingPlayer;
		UCentipedeWaterOutletEventHandler::Trigger_OnUnplugWaterOutlet(this, Data);
	}

	UFUNCTION()
	private void HandleBiteStarted(FCentipedeBiteEventParams BiteParams)
	{
		BitePlayer = BiteParams.Player;
		SprayPlayer = BiteParams.Player.OtherPlayer;

		UPlayerCentipedeComponent::Get(BitePlayer).bBitingWater = true;
		UPlayerCentipedeComponent::Get(SprayPlayer).bShootingWater = true;

		OutletVFXComp.Deactivate();
		SprayVFXComp.Activate();

		//Play force feedback
		BitePlayer.PlayForceFeedback(BiteStartForceFeedbackEffect, false, true, this);
		BitePlayer.PlayForceFeedback(PulsingForceFeedbackEffect, true, true, this);
		SprayPlayer.PlayForceFeedback(PulsingForceFeedbackEffect, true, true, this);

		SprayPlayer.BlockCapabilities(CentipedeTags::CentipedeBite, this);

		SetActorTickEnabled(true);
		bSpouting = true;

		WaterImpactOffset.SnapTo(-WaterTriggerComp.CapsuleHalfHeight);
	}

	UFUNCTION()
	private void HandleBiteStopped(FCentipedeBiteEventParams BiteParams)
	{
		if (bWaterLeft)
			OutletVFXComp.Activate();

		SprayVFXComp.Deactivate();

		BitePlayer.StopForceFeedback(this);
		SprayPlayer.StopForceFeedback(this);

		SprayPlayer.UnblockCapabilities(CentipedeTags::CentipedeBite, this);

		UPlayerCentipedeComponent::Get(BitePlayer).bBitingWater = false;
		UPlayerCentipedeComponent::Get(SprayPlayer).bShootingWater = false;

		bSpouting = false;
	}

	float TimeStampLastLavaHit = -1.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (SprayPlayer != nullptr && bWaterLeft)
		{
			// vfx!
			UPlayerCentipedeComponent PlayerCentipedeComponent = UPlayerCentipedeComponent::Get(SprayPlayer);
			FTransform CentipedeHeadTransform = PlayerCentipedeComponent.GetMeshHeadTransform();
			SprayVFXComp.SetWorldLocationAndRotation(CentipedeHeadTransform.Translation, CentipedeHeadTransform.Rotation);
			SpoutDirection = CentipedeHeadTransform.Rotation.ForwardVector;
			SpoutDirection.Z = 0.0;
			SpoutDirection = SpoutDirection.GetSafeNormal();

			if (SanctuaryCentipedeDevToggles::Draw::WaterThings.IsEnabled())
				Debug::DrawDebugCoordinateSystem(SprayPlayer.ActorLocation, FRotator::MakeFromX(SpoutDirection), 200.0, 3.0, 0.0, true);

			if (bSpouting)
			{
				SpoutCooldown -= DeltaSeconds;
				if (SpoutCooldown <= 0.0)
				{
					AssignWaterSpoutyCooldown();
					SpawnWaterSpouty();
				}
			}

			AccVelocityWeight.AccelerateTo(SprayPlayer.ActorVelocity.Size() > KINDA_SMALL_NUMBER ? 1.0 : 0.0, 0.33, DeltaSeconds);

			// update timers, remove if overtime
			int Num = WaterSpouts.Num();
			for (int i = 0; i < Num; ++i)
			{
				WaterSpouts[i].InterpolationTimer += DeltaSeconds;
				if (WaterSpouts[i].InterpolationTimer >= WaterLifetime)
				{
					WaterSpouts.RemoveAt(i);
					// Splash at location?
					--i;
					--Num;
				}
			}

			bool bHitLavaForVFX = false;
			TArray<FVector> VFX_WaterGunLocations;
			VFX_WaterGunLocations.Reserve(WaterSpouts.Num());

			// collision checkz!
			FVector LastLocation = FVector::ZeroVector;
			for (int i = 0; i < WaterSpouts.Num(); ++i)
			{
				float Interpolation = Math::Clamp(WaterSpouts[i].InterpolationTimer / WaterLifetime, 0.0, 1.0);
				// Circular Ease Out
				float ReverseInterpolation = 1.0 - Interpolation;
				Interpolation = Math::Sqrt(1 - ReverseInterpolation*ReverseInterpolation);
				Interpolation = Interpolation * Interpolation * Interpolation;

				FVector CurrentLocation = Math::Lerp(WaterSpouts[i].StartLocation, WaterSpouts[i].EndLocation, Interpolation);
				VFX_WaterGunLocations.Insert(CurrentLocation, 0);

				if (i > 0 && SanctuaryCentipedeDevToggles::Draw::WaterThings.IsEnabled())
				{
					FVector Diff = CurrentLocation - LastLocation;
					FVector MiddlePoint = LastLocation + Diff * 0.5;
					FRotator CapsuleRotation = FRotator::MakeFromXZ(FVector::UpVector, Diff.GetSafeNormal()); 
					Debug::DrawDebugCapsule(MiddlePoint, Diff.Size() * 0.5, 20.0, CapsuleRotation, ColorDebug::Eggblue, 5, 0.0, true);
				}

				bool bHitLava = TraceFreezeLavaRay(CurrentLocation);
				LastLocation = CurrentLocation;
				// we have a valid hit as long as the "lava spline" hit something. So we don't check interpolation here.
				if(bHitLava)
				{
					TimeStampLastLavaHit = Time::GetGameTimeSeconds();
				}

				// we want to send valid lava hits to niagara when the end particles are close 
				// to their end target, and we also want that value to be true for as long as the lava is dissolving. 
				const float TimeSinceLastLavaHit = Time::GetGameTimeSince(TimeStampLastLavaHit);
				if(TimeSinceLastLavaHit < 0.1 && Interpolation > 0.90)
				{
					bHitLavaForVFX = true;
					// Debug::DrawDebugPoint(CurrentLocation, 20, FLinearColor::Green);
				}
			}

			if(SprayVFXComp != nullptr)
			{
				// Debug::DrawDebugString(SprayVFXComp.WorldLocation, "Lava: " + bHitLavaForVFX);
				SprayVFXComp.SetNiagaraVariableBool("HitLava", bHitLavaForVFX);
				NiagaraDataInterfaceArray::SetNiagaraArrayVector(SprayVFXComp, n"GP_Locations", VFX_WaterGunLocations);
			}

		}
		else if (bPlugged)
		{
			OutletVFXComp.Deactivate();
		}
		else if (SanctuaryCentipedeDevToggles::ReplugWaterOutlet.IsEnabled() && !bPlugged)
		{
			DevToggleReplugTimer -= DeltaSeconds;
			if (WaterPlugClass != nullptr && !bBlockedByRubble && DevToggleReplugTimer < 0.0)
			{
				SpawnPlug();
			}
		}
	}

	private void AssignWaterSpoutyCooldown()
	{
		while (SpoutCooldown < 0.0)
			SpoutCooldown += SpoutInterval;
		SpoutCooldown = Math::Clamp(SpoutCooldown, 0.0, SpoutInterval);
	}

	private void SpawnWaterSpouty()
	{
		FVector PredictedDirection = Math::Lerp(SpoutDirection, SpoutDirection + SprayPlayer.ActorVelocity.GetSafeNormal() * 0.4, AccVelocityWeight.Value);
		PredictedDirection = PredictedDirection.GetSafeNormal();

		if (SanctuaryCentipedeDevToggles::Draw::WaterThings.IsEnabled())
			Debug::DrawDebugLine(SprayPlayer.ActorLocation, SprayPlayer.ActorLocation + PredictedDirection * WaterEndDistance, ColorDebug::White, 3.0, 1.0, false);

		if (LastSpoutyDirection.Size() > KINDA_SMALL_NUMBER)
		{
			// check if angle is too great, then spawn more water spouties
			FVector StepDirection = PredictedDirection;

			float CurrentAngle = Math::Atan2(LastSpoutyDirection.Y, LastSpoutyDirection.X);
			float NextAngle = Math::Atan2(PredictedDirection.Y, PredictedDirection.X);
			float MinAngleStep = Math::DegreesToRadians(20.0);

			float AngleDiff = Math::Abs(NextAngle - CurrentAngle);
			if (AngleDiff > PI)
			{
				if (NextAngle < CurrentAngle)
					CurrentAngle -= PI * 2.0;
				else if (NextAngle >= CurrentAngle)
					CurrentAngle += PI * 2.0;

				AngleDiff = Math::Abs(NextAngle - CurrentAngle);
				// float DiffDegrees = Math::RadiansToDegrees(AngleDiff);
				// PrintToScreen("Tot Angle: " + DiffDegrees, 1.0, ColorDebug::Carrot);
			}

			{
				float AngleStep = Math::Max(AngleDiff / 12.0, MinAngleStep);
				int NumSteps = int(AngleDiff / AngleStep);
				float FloatNumSteps = float(NumSteps);
				for (int iStep = 0; iStep < NumSteps; iStep++)
				{
					float FloatStep = float(iStep);
					float Alpha = FloatStep / FloatNumSteps;
					float StepAngle = Math::Lerp(CurrentAngle, NextAngle, Alpha);

					// PrintToScreen("Angle Div: " + Math::RadiansToDegrees(StepAngle), 1.0, ColorDebug::Carrot);
					StepDirection.X = Math::Cos(StepAngle);
					StepDirection.Y = Math::Sin(StepAngle);

					if (SanctuaryCentipedeDevToggles::Draw::WaterThings.IsEnabled())
						Debug::DrawDebugLine(SprayPlayer.ActorLocation, SprayPlayer.ActorLocation + StepDirection * WaterEndDistance, ColorDebug::Rainbow(2.0), 3.0, 0.5, false);

					SpawnWaterSpoutyInDirection(StepDirection);
				}
			}
		}
		
		SpawnWaterSpoutyInDirection(PredictedDirection);
		LastSpoutyDirection = PredictedDirection;
	}

	private void SpawnWaterSpoutyInDirection(FVector Direction)
	{
		FCentipedeWaterSpoutData SpoutData;
		SpoutData.StartLocation = SprayPlayer.ActorLocation + Direction * WaterStartDistance;
		SpoutData.EndLocation = SpoutData.StartLocation + Direction * WaterEndDistance;
		SpoutData.InterpolationTimer = 0.0;

		if(SprayVFXComp != nullptr)
		{
			const FVector VFXStartVelocity = (SpoutData.EndLocation - SpoutData.StartLocation) / WaterLifetime;
			SprayVFXComp.SetVariableVec3(n"GP_Velocity", VFXStartVelocity);
			SprayVFXComp.SetVariableFloat(n"GP_LifeTime", WaterLifetime);
			SprayVFXComp.SetVariableVec3(n"GP_ImpactLocation", SpoutData.EndLocation);
		}

		WaterSpouts.Add(SpoutData);
		if (WaterSpouts.Num() > ReservedSpouts)
		{
			PrintToScreen("SpawnWaterSpouty: Should reserve water spouts with number " + WaterSpouts.Num(), 5.0);
		}
	}

	// return true / false depending on if we hit lava related geo
	private bool TraceFreezeLavaRay(FVector Location)
	{
		const float TraceLength = 300.0;
		FHazeTraceSettings GroundTrace = Trace::InitObjectType(EObjectTypeQuery::WorldStatic);
		GroundTrace.IgnoreActor(this);
		FHitResult GroundResult = GroundTrace.QueryTraceSingle(Location, Location - FVector::UpVector * TraceLength);
		if (GroundResult.bBlockingHit)
			return false;

		bool bHitLava = false;
		FHazeTraceSettings Tracey = Trace::InitObjectType(EObjectTypeQuery::WorldDynamic);
		Tracey.IgnoreActor(this);
		// Tracey.DebugDraw(0.1);
		FHitResult Result = Tracey.QueryTraceSingle(Location, Location - FVector::UpVector * TraceLength);
		if (Result.bBlockingHit)
		{
			// no lava mom anymore
			// auto LavaMom = Cast<ASanctuaryLavaMom>(Result.Actor);
			// if (LavaMom != nullptr)
			// {
			// 	LavaMom.Freeze();
			// 	BiteResponseComp.SetUsableByPlayers(EHazeSelectPlayer::None);
			// 	bWaterLeft = false;
			// 	SprayVFXComp.Deactivate();
			// 	bHitLava = true;
			// }

			bool bDebugHit = true;
			auto Lava = Cast<ASanctuaryCentipedeFreezableLava>(Result.Actor);
			if (Lava != nullptr && !Lava.bDisabledSpawningRocks)
			{
				Lava.Freeze(Result.ImpactPoint);
				bDebugHit = false;
				bHitLava = true;
			}

			auto LavaRock = Cast<ASanctuaryCentipedeFrozenLavaRock>(Result.Actor);
			if (LavaRock != nullptr && LavaRock.IsMelting())
			{
				bDebugHit = false;
				LavaRock.ReFreeze();
				// bHitLava = true;
			}

			auto LavaSpline = Cast<ASanctuaryCentipedeLavaSpline>(Result.Actor);
			if (LavaSpline != nullptr)
			{
				bDebugHit = false;
				auto FlowingLava = Cast<USanctuaryCentipedeLavaSplineSegmentComponent>(Result.Component);
				if (FlowingLava != nullptr)
					FlowingLava.Freeze(Result.ImpactPoint);
				bHitLava = true;
			}

			if (bDebugHit)
			{
				// Debug::DrawDebugString(Result.ImpactPoint, "" + Result.Actor.GetName());
				// Debug::DrawDebugPoint(Result.ImpactPoint, 10, FLinearColor::Green);
			}
		}

		return bHitLava;
	}

	FVector GetLetGoPushForce() const
	{
		return -TargetTransformComp.ForwardVector * LetGoPushMagnitude;
	}
};