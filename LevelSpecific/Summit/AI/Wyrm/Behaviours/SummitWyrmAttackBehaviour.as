class USummitWyrmAttackBehaviour : UBasicBehaviour

{

	default Requirements.Add(EBasicBehaviourRequirement::Weapon);



	USummitWyrmSettings WyrmSettings;



	bool bIsAttacking = false;

	float InAttackPositionDuration = 0;

	float EvadeDuration = 0;



	float DamageTime = 0;



	AHazePlayerCharacter PlayerTarget;



	UFUNCTION(BlueprintOverride)

	void Setup()

	{

		Super::Setup();

		WyrmSettings = USummitWyrmSettings::GetSettings(Owner);

	}



	UFUNCTION(BlueprintOverride)

	void PreTick(float DeltaTime)

	{



		if (IsBlocked())

		{

			InAttackPositionDuration = 0;

			return;

		}



		if (!TargetComp.HasValidTarget())

		{

			InAttackPositionDuration = 0;

			return;

		}



		if (SceneView::IsInView(Cast<AHazePlayerCharacter>(TargetComp.Target), Owner.ActorLocation))

		{

			InAttackPositionDuration += DeltaTime;

		}

		else

		{

			InAttackPositionDuration = 0;

		}

	}



	UFUNCTION(BlueprintOverride)

	bool ShouldActivate() const

	{

		if (!Super::ShouldActivate())

			return false;

		if (!TargetComp.HasValidTarget())

			return false;

		if (InAttackPositionDuration < WyrmSettings.AttackInPositionMinDuration)

			return false;

		

		return true;

	}



	UFUNCTION(BlueprintOverride)

	bool ShouldDeactivate() const

	{

		if (Super::ShouldDeactivate())

			return true;

		if (!TargetComp.HasValidTarget())

			return true;

		if (EvadeDuration > WyrmSettings.AttackEvadeMinDuration)

			return true;



		return false;

	}



	UFUNCTION(BlueprintOverride)

	void OnActivated()

	{

		Super::OnActivated();



		bIsAttacking = false;

		DamageTime = BIG_NUMBER;

		EvadeDuration = 0;



		PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);

		

		USummitWyrmEffectHandler::Trigger_OnTelegraphAttack(Owner);

	}



	UFUNCTION(BlueprintOverride)

	void OnDeactivated()

	{

		Super::OnDeactivated();

		if (bIsAttacking)

		{

			USummitWyrmEffectHandler::Trigger_OnEndAttack(Owner);

		}

		else

		{

			USummitWyrmEffectHandler::Trigger_OnEndTelegraphAttack(Owner);

		}



		InAttackPositionDuration = 0;

	}



	UFUNCTION(BlueprintOverride)

	void TickActive(float DeltaTime)

	{

		if (!bIsAttacking && ActiveDuration > WyrmSettings.AttackTelegraphDuration)

		{



			bIsAttacking = true;

			DamageTime = Time::GameTimeSeconds;

			USummitWyrmEffectHandler::Trigger_OnEndTelegraphAttack(Owner);

			USummitWyrmEffectHandler::Trigger_OnAttack(Owner, FWyrmAttackTargetParams(TargetComp.Target));

		}



		if (Time::GameTimeSeconds > DamageTime)

		{

			DamageTime += WyrmSettings.AttackDamageInterval;

			if (PlayerTarget.HasControl())

			{

				PlayerTarget.DealBatchedDamageOverTime(WyrmSettings.AttackDamagePerSecond * WyrmSettings.AttackDamageInterval, FPlayerDeathDamageParams());

			}

		}



		// Target counts as evading if they shake us so we're out of view or manage to get behind us

		float CosOfAngle = Owner.ActorForwardVector.DotProduct((PlayerTarget.ActorLocation - Owner.ActorLocation).GetSafeNormal());

		if (CosOfAngle < 0.5) // not within 60 deg FOV

		{

			EvadeDuration += DeltaTime;

		}



	}



}