event void FSkylineAttackShipShieldSignature();

struct FSkylineAttackShipShieldData
{
	FVector Location;
	float Radius;
	float LifeSpan;
}

class USkylineAttackShipShieldComponent : UStaticMeshComponent
{
	TArray<FSkylineBossForceFieldData> ShieldImpacts;
	int MaxImpacts = 10;
	UMaterialInstanceDynamic MID;

	TArray<FName> LocationParams;
	TArray<FName> RadiusParams;

	float ShieldOpacity = 0.5;

	float Health = 1.0;

	bool bIsBroken = false;

	UPROPERTY(EditAnywhere)
	FLinearColor FullColor = FLinearColor::Blue;

	UPROPERTY(EditAnywhere)
	FLinearColor MinColor = FLinearColor::Red;

	UPROPERTY()
	FSkylineAttackShipShieldSignature OnShieldBreak;

	UPROPERTY()
	FSkylineAttackShipShieldSignature OnShieldRegenerate;

	ASkylineAttackShip GetAttackShip() const property
	{
		return Cast<ASkylineAttackShip>(GetOwner());
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MID = CreateDynamicMaterialInstance(0);
	
		for (int i = 0; i < MaxImpacts; i++)
		{
			LocationParams.Add(FName("Bubble" + i + n"Loc"));
			RadiusParams.Add(FName("Bubble" + i + n"Radius"));
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FLinearColor Color = Math::Lerp(MinColor, FullColor, Health) * 1.0;
		MID.SetVectorParameterValue(n"EmissiveColor", Color);

//		MID.SetScalarParameterValue(n"MinOpacity", ShieldOpacity);
		ShieldOpacity = Math::Max(0.0, ShieldOpacity - 0.5 * DeltaSeconds) * 10.0;

		int NumOfFields = ShieldImpacts.Num();
		for (int i = NumOfFields - 1; i >= 0; i--)
		{
			auto& ForceFieldImpact = ShieldImpacts[i];
			
			ForceFieldImpact.LifeSpan -= DeltaSeconds;

			if (ForceFieldImpact.LifeSpan <= 0.0)
				ShieldImpacts.RemoveAt(i);
		}
	
		UpdateImpactMID();
	
	//	PrintToScreen("Shield Health: " + Health, 0.0, FLinearColor::Green);
	}

	UFUNCTION()
	void DamageShield(FVector Location, float Damage)
	{
		if (bIsBroken)
			return;

		AddImpact(Location, 200.0, 2.0);

		Health -= Damage;

		FSkylineAttackShipShieldEventData Params;
		Params.ShieldDamageAmount = Damage;
		Params.bShieldBreak = Health <= 0.0;
		USkylineAttackShipEventHandler::Trigger_OnShieldDamage(AttackShip, Params);

		if (Health <= 0.0)
			BreakShield();
	}

	UFUNCTION()
	void BreakShield()
	{
		bIsBroken = true;
		SetCollisionEnabled(ECollisionEnabled::NoCollision);
		SetVisibility(false);
		OnShieldBreak.Broadcast();
	}

	void AddImpact(FVector ImpactWorldLocation, float Radius, float LifeSpan)
	{
		ShieldOpacity = Math::Min(ShieldOpacity + 0.5, 0.5);

		FSkylineBossForceFieldData ImpactData;
		ImpactData.Location = WorldTransform.InverseTransformPositionNoScale(ImpactWorldLocation);
		ImpactData.Radius = Radius;
		ImpactData.LifeSpan = LifeSpan;

		if (ShieldImpacts.Num() == 10)
			ShieldImpacts.RemoveAt(0);

		ShieldImpacts.Add(ImpactData);
	}

	void UpdateImpactMID()
	{
		for (int i = 0; i < MaxImpacts; i++)
		{
			if (ShieldImpacts.IsValidIndex(i))
			{
				auto& ImpactData = ShieldImpacts[i];

				FVector Location = WorldTransform.TransformPositionNoScale(ImpactData.Location);

				MID.SetVectorParameterValue(LocationParams[i], FLinearColor(Location));
				MID.SetScalarParameterValue(RadiusParams[i], ImpactData.Radius * ImpactData.LifeSpan);
			}
			else
			{
				MID.SetVectorParameterValue(LocationParams[i], FLinearColor(FVector::ZeroVector));
				MID.SetScalarParameterValue(RadiusParams[i], 0.0);
			}
		}
	}
}