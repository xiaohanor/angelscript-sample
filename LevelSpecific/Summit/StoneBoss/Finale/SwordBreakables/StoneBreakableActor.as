event void FOnStoneBreakableActorDestroyed();

struct FStoneBreakableDragonSwordHitParams
{
	FDragonSwordHitData HitData;
	float LastHitTime;
}

class AStoneBreakableActor : AHazeActor
{
	UPROPERTY()
	FOnStoneBreakableActorDestroyed OnStoneBreakableActorDestroyed;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HealthbarAttachRoot;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UDragonSwordCombatResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent AIHealthComp;

	UPROPERTY(DefaultComponent)
	UDragonSwordCombatTargetComponent TargetComp;
	default TargetComp.bCanRushTowards = false;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StoneBreakableHealthRegenCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"StoneBreakableHealthRegenBlockerCapability");

	UPROPERTY(DefaultComponent)
	UStoneBreakableHealthRegenComponent RegenComp;

	UPROPERTY(EditAnywhere)
	bool bStartActive = true;

	FLinearColor HurtBaseColor = FLinearColor::Red;
	FLinearColor HurtEmissiveColor = FLinearColor::Black;

	FLinearColor StartBaseColor;
	FLinearColor StartEmissiveColor;

	UBasicAIHealthBarSettings AIHealthBarSettings;
	UBasicAIHealthSettings HealthSettings;
	UBasicAIHealthBarSettings HealthBarSettings;

	TPerPlayer<FStoneBreakableDragonSwordHitParams> PlayerHitParams;

	UMaterialInstanceDynamic MaterialInstanceDynamic;

	// Max time between both players swings to disable regen
	float MaxTimeBetweenPlayerSwings = 4.0;

	UPROPERTY(EditAnywhere)
	float TakeDamage = 0.3;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthSettings = UBasicAIHealthSettings::GetSettings(this);
		HealthBarSettings = UBasicAIHealthBarSettings::GetSettings(Cast<AHazeActor>(this));

		HealthSettings.TakeDamageCooldown = 0.2;
		HealthBarSettings.HealthBarOffset = FVector(0, 0, -180);

		ResponseComp.OnHit.AddUFunction(this, n"OnHit");

		MaterialInstanceDynamic = MeshComp.CreateDynamicMaterialInstance(0);
		StartBaseColor = MaterialInstanceDynamic.GetVectorParameterValue(n"BaseColor");
		StartEmissiveColor = MaterialInstanceDynamic.GetVectorParameterValue(n"EmissiveColor");

		if (!bStartActive)
			AddActorDisable(this);
	}

	UFUNCTION()
	void SetBreakableActorActiveState(bool bSetToActive = true)
	{
		if (bSetToActive)
			RemoveActorDisable(this);
		else
			AddActorDisable(this);
	}

	void UpdateHealthVisual(float Fraction)
	{
		FLinearColor NewBaseColor;
		NewBaseColor.R = Math::Lerp(HurtBaseColor.R, StartBaseColor.R, Fraction);
		NewBaseColor.G = Math::Lerp(HurtBaseColor.G, StartBaseColor.G, Fraction);
		NewBaseColor.B = Math::Lerp(HurtBaseColor.B, StartBaseColor.B, Fraction);
		NewBaseColor.A = Math::Lerp(HurtBaseColor.A, StartBaseColor.A, Fraction);
		MaterialInstanceDynamic.SetVectorParameterValue(n"BaseColor", NewBaseColor);

		FLinearColor NewEmissiveColor;
		NewEmissiveColor.R = Math::Lerp(HurtEmissiveColor.R, StartEmissiveColor.R, Fraction);
		NewEmissiveColor.G = Math::Lerp(HurtEmissiveColor.G, StartEmissiveColor.G, Fraction);
		NewEmissiveColor.B = Math::Lerp(HurtEmissiveColor.B, StartEmissiveColor.B, Fraction);
		NewEmissiveColor.A = Math::Lerp(HurtEmissiveColor.A, StartEmissiveColor.A, Fraction);
		MaterialInstanceDynamic.SetVectorParameterValue(n"EmissiveColor", NewEmissiveColor);
	}

	UFUNCTION()
	private void OnHit(UDragonSwordCombatUserComponent CombatComp, FDragonSwordHitData HitData, AHazeActor Instigator)
	{
		FDragonSwordBreakableHitParams EffectParams;
		EffectParams.Location = HitData.ImpactPoint;
		EffectParams.HealthAlpha = AIHealthComp.GetHealthFraction();
		UStoneBreakableEffectHandler::Trigger_Hit(this, EffectParams);

		FStoneBreakableDragonSwordHitParams HitParams;
		HitParams.HitData = HitData;
		HitParams.LastHitTime = Time::GameTimeSeconds;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Instigator);
		if (Player == nullptr)
		{
			return;
		}
		PlayerHitParams[Player] = HitParams;

		if (Time::GetGameTimeSince(PlayerHitParams[Player.OtherPlayer].LastHitTime) < MaxTimeBetweenPlayerSwings)
		{
			RegenComp.DisableRegen();
		}

		AIHealthComp.TakeDamage(TakeDamage, EDamageType::Impact, this);

		if (AIHealthComp.GetHealthFraction() <= 0.0)
			BreakableDeath();
	}

	UFUNCTION()
	void BreakableDeath()
	{
		TArray<UStaticMeshComponent> MeshComps;
		GetComponentsByClass(MeshComps);

		for (UStaticMeshComponent Mesh : MeshComps)
		{
			Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			Mesh.SetHiddenInGame(true);
			FDragonSwordBreakableDeathParams Params;
			Params.Location = ActorLocation;
			UStoneBreakableEffectHandler::Trigger_Death(this, Params);
		}

		MeshComp.SetHiddenInGame(true);
		MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		TargetComp.Disable(this);

		OnStoneBreakableActorDestroyed.Broadcast();
	}

	UFUNCTION()
	void SetEndState()
	{
		MeshComp.SetHiddenInGame(true);
		MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		TArray<UStaticMeshComponent> MeshComps;
		GetComponentsByClass(MeshComps);

		for (UStaticMeshComponent Mesh : MeshComps)
		{
			Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			Mesh.SetHiddenInGame(true);
		}

		TargetComp.Disable(this);
	}
};