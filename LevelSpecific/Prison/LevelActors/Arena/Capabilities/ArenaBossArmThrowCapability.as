class UArenaBossArmThrowCapability : UArenaBossBaseCapability
{
	default RequiredState = EArenaBossState::ArmThrow;
	default bResetToIdleOnDeactivation = false;

	default ChargeUpDuration = 0.0;
	default WindDownDuration = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		UArenaBossEffectEventHandler::Trigger_ArmThrowStateEntered(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		UArenaBossEffectEventHandler::Trigger_ArmThrowStateEnded(Boss);

		Boss.ActivateState(EArenaBossState::FacePunch);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Loc = Math::VInterpTo(Boss.ActorLocation, Boss.DefaultLocation, DeltaTime, 2.0);
		Boss.SetActorLocation(Loc);

		Super::TickActive(DeltaTime);

		if (IsChargingUpOrWindingDown())
			return;

		if (ActiveDuration >= 3.2)
			StartWindingDown();

		FVector TraceLoc = Boss.ArmActor.ArmMeshComp.GetSocketLocation(n"Base");
		FVector Dir = Boss.ArmActor.ArmMeshComp.GetSocketRotation(n"Base").UpVector;
		Dir = Dir.ConstrainToPlane(FVector::UpVector);
		TraceLoc += Dir * 1000.0;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.UseBoxShape(1000.0, 200.0, 200.0, FQuat(Dir.Rotation()));

		/*FHazeTraceDebugSettings Debug;
		Debug.Thickness = 20.0;
		Debug.TraceColor = FLinearColor::Red;
		Trace.DebugDraw(Debug);*/

		FOverlapResultArray OverlapResults = Trace.QueryOverlaps(TraceLoc);
		for (FOverlapResult Result : OverlapResults)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Result.Actor);
			if (Player != nullptr)
			{
				FVector DamageDir = (Player.ActorLocation - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
				Player.DamagePlayerHealth(0.9, FPlayerDeathDamageParams(DamageDir), Boss.ImpactDamageEffect, Boss.ImpactDeathEffect);
				Player.ApplyKnockdown(-FVector::ForwardVector * 50.0);
			}
		}
	}

	void ChargedUp() override
	{
		Super::ChargedUp();
		UArenaBossEffectEventHandler::Trigger_ArmThrowAttack(Boss);
	}

	void StartWindingDown() override
	{
		Super::StartWindingDown();
	}
}