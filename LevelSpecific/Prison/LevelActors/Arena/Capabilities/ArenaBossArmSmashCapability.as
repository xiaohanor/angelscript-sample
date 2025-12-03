class UArenaBossArmSmashCapability : UArenaBossBaseCapability
{
	default RequiredState = EArenaBossState::ArmSmash;
	default bResetToIdleOnDeactivation = false;

	default ChargeUpDuration = 5.6;
	default WindDownDuration = 0.5;

	float RipOffArmTime = 0.0;
	float RipOffArmDuration = 5.6;

	float RaiseArmTime = 0.0;
	float RaiseArmDuration = 0.75;

	float SmashTime = 0.0;
	float SmashDuration = 6.933333;

	int Smashes = 0;
	float CurrentIndividualSmashTime = 0.0;
	float SmashInterval = 1.15;

	EArenaBossArmSmashState CurrentState;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Boss.HideRightArm(true, false);
		Boss.ArmActor.bRipping = true;

		Smashes = 0;
		SmashInterval = 0.2;
		CurrentIndividualSmashTime = 0.0;

		Timer::SetTimer(this, n"HideShoulderPad", 5.5);

		UArenaBossEffectEventHandler::Trigger_ArmSmashStateEntered(Boss);
	}

	UFUNCTION()
	private void HideShoulderPad()
	{
		Boss.Mesh.HideBoneByName(n"RightShoulderPad", EPhysBodyOp::PBO_None);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Boss.ActivateState(EArenaBossState::BatBomb);

		UArenaBossEffectEventHandler::Trigger_ArmSmashStateEnded(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		FVector Loc = Math::VInterpTo(Boss.ActorLocation, Boss.DefaultLocation, DeltaTime, 5.0);
		FRotator Rot = Math::RInterpTo(Boss.ActorRotation, FRotator(0.0, 180.0, 0.0), DeltaTime, 5.0);
		Boss.SetActorLocationAndRotation(Loc, Rot);

		if (IsChargingUpOrWindingDown())
			return;

		if (CurrentState == EArenaBossArmSmashState::RaisingArm)
		{
			RaiseArmTime += DeltaTime;
			if (RaiseArmTime >= RaiseArmDuration)
				ArmRaised();
		}

		else if (CurrentState == EArenaBossArmSmashState::Smashing)
		{
			FVector TraceLoc = Boss.ArmActor.ArmMeshComp.GetSocketLocation(n"Base");
			FVector Dir = Boss.ArmActor.ArmMeshComp.GetSocketRotation(n"Base").UpVector;
			Dir = Dir.ConstrainToPlane(FVector::UpVector);
			TraceLoc += Dir * 1000.0;

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.UseBoxShape(1000.0, 150.0, 200.0, FQuat(Dir.Rotation()));

			/*FHazeTraceDebugSettings Debug;
			Debug.Thickness = 20.0;
			Debug.TraceColor = FLinearColor::Red;
			Trace.DebugDraw(Debug);*/

			FOverlapResultArray OverlapResults = Trace.QueryOverlaps(TraceLoc);
			for (FOverlapResult Result : OverlapResults)
			{
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Result.Actor);
				if (Player != nullptr)
					Player.KillPlayer(FPlayerDeathDamageParams(FVector::DownVector), Boss.ImpactDeathEffect);
			}

			SmashTime += DeltaTime;
			if (SmashTime >= SmashDuration)
				StartWindingDown();

			CurrentIndividualSmashTime += DeltaTime;
			if (CurrentIndividualSmashTime >= SmashInterval && Smashes < 6)
			{
				CurrentIndividualSmashTime = 0.0;
				SmashInterval = 1.15;
				Smashes++;
				Boss.ArmActor.SmashTriggered(Boss.DefaultLocation.Z);
			}
		}
	}

	void ArmRippedOff()
	{
		Boss.ArmActor.bRaising = true;
		CurrentState = EArenaBossArmSmashState::RaisingArm;
		Boss.AnimationData.ArmSmashState = EArenaBossArmSmashState::RaisingArm;
	}

	void ArmRaised()
	{
		Boss.ArmActor.bSmashing = true;
		CurrentState = EArenaBossArmSmashState::Smashing;
		Boss.AnimationData.ArmSmashState = EArenaBossArmSmashState::Smashing;

		UArenaBossEffectEventHandler::Trigger_ArmSmashAttackSequenceStarted(Boss);
	}

	void ChargedUp() override
	{
		Super::ChargedUp();

		ArmRippedOff();
	}

	void StartWindingDown() override
	{
		Super::StartWindingDown();

		Boss.ArmActor.bLowering = true;

		UArenaBossEffectEventHandler::Trigger_ArmSmashStateWindDown(Boss);
	}
}

enum EArenaBossArmSmashState
{
	RippingOffArm,
	RaisingArm,
	Smashing,
	Exiting
}