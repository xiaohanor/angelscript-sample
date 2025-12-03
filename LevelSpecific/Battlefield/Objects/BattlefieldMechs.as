class ABattlefieldMechs : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Legs;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CoreLower;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CoreUpper;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Torso;

	UPROPERTY(DefaultComponent, Attach = Torso)
	UStaticMeshComponent LeftArm;

	UPROPERTY(DefaultComponent, Attach = LeftArm)
	UStaticMeshComponent LeftWeapon;

	UPROPERTY(DefaultComponent, Attach = LeftWeapon)
	UNiagaraComponent LeftEffectComp;
	default LeftEffectComp.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Torso)
	UStaticMeshComponent RightArm;

	UPROPERTY(DefaultComponent, Attach = RightArm)
	UStaticMeshComponent RightWeapon;

	UPROPERTY(DefaultComponent, Attach = RightWeapon)
	UNiagaraComponent RightEffectComp;
	default RightEffectComp.SetAutoActivate(false);

	UPROPERTY(EditAnywhere, Category = "Movement")
	bool bRotateTorso;

	UPROPERTY(EditAnywhere, Category = "Movement", meta = (EditCondition = "bRotateTorso", EditConditionHides))
	float TorsoRotationSpeed = 1.25;

	UPROPERTY(EditAnywhere, Category = "Movement", meta = (EditCondition = "bRotateTorso", EditConditionHides))
	float RotationDegrees = 25.0;

	bool bFiringLeft;
	float LeftFireDuration = 2.5;
	float LeftWaitDuration = 1.5;
	float LeftCurrentFireTime;
	float LeftCurrentWaitTime;

	bool bFiringRight;
	float RightFireDuration = 1.0;
	float RightWaitDuration = 2.0;
	float RightCurrentFireTime;
	float RightCurrentWaitTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LeftFireDuration += Math::RandRange(0.0, 1.0);
		LeftWaitDuration += Math::RandRange(0.0, 1.0);
		RightFireDuration += Math::RandRange(0.0, 1.0);
		RightWaitDuration += Math::RandRange(0.0, 1.0);

		RightCurrentWaitTime = RightWaitDuration;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bRotateTorso)
		{
			float Sin = Math::Sin(Time::GameTimeSeconds * TorsoRotationSpeed);
			float Amount = RotationDegrees * Sin;
			Torso.RelativeRotation = FRotator(0.0, Amount, 0.0);
		}	

		if (RightCurrentFireTime < 0.0)
		{
			if (bFiringRight)
			{
				bFiringRight = false;
				RightEffectComp.Deactivate();
			}

			RightCurrentWaitTime -= DeltaSeconds;

			if (RightCurrentWaitTime < 0.0)
			{
				RightCurrentFireTime = RightFireDuration;
				RightCurrentWaitTime = RightWaitDuration;
				RightEffectComp.Activate();
				bFiringRight = true;
				UBattleMechEventHandler::Trigger_OnMechStartRight(this, FBattleMechParams(RightEffectComp));
			}
		}
		else
		{
			UBattleMechEventHandler::Trigger_OnMechStopRight(this);
			RightCurrentFireTime -= DeltaSeconds;
		}

		
		if (LeftCurrentFireTime < 0.0)
		{
			if (bFiringLeft)
			{
				bFiringLeft = false;
				UBattleMechEventHandler::Trigger_OnMechStopLeft(this);
				LeftEffectComp.Deactivate();
			}

			LeftCurrentWaitTime -= DeltaSeconds;

			if (LeftCurrentWaitTime < 0.0)
			{
				LeftCurrentFireTime = LeftFireDuration;
				LeftCurrentWaitTime = LeftWaitDuration;
				LeftEffectComp.Activate();
				bFiringLeft = true;
				UBattleMechEventHandler::Trigger_OnMechStartLeft(this, FBattleMechParams(LeftEffectComp));
			}
		}
		else
		{
			LeftCurrentFireTime -= DeltaSeconds;
		}
	}
};