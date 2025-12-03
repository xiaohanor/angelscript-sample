struct FPlayerDamageTakenEffectParams
{
	UPROPERTY()
	float DamageAmount;

	UPROPERTY()
	UNiagaraSystem EffectSystem;

	UPROPERTY()
	FSoundDefReference EffectSoundDef;

	UPROPERTY()
	FPlayerDeathDamageParams DeathDamageParams;
}

struct FPlayerHealedEffectParams
{
	UPROPERTY()
	float HealAmount;
}

struct FPlayerHealthUpdatedParams
{
	UPROPERTY()
	float NewHealth;
	UPROPERTY()
	bool bIsDead;
}

UCLASS(Abstract)
class UPlayerDamageEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UDeathRespawnEffectSettings EffectSettings;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve DamageEffectCurve;
	default DamageEffectCurve.AddDefaultKey(0.0, 0.0);
	default DamageEffectCurve.AddDefaultKey(1.0, 1.0);

	private TArray<UMeshComponent> MeshesWithOverlayMaterial;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		EffectSettings = UDeathRespawnEffectSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DamageTaken(FPlayerDamageTakenEffectParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Healed(FPlayerHealedEffectParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HealthUpdated(FPlayerHealthUpdatedParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayerDied(FPlayerDeathDamageParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayerRevived()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HealthRegenerated()
	{
	}

	/**
	 * Triggered when the player would have taken damage, but because they are currently invulnerable,
	 * they have not actually taken any damage.
	 * 
	 * Note that this is rate limited and will not occur more than 5 times per second.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AvoidedDamageByInvulnerable(FPlayerDamageTakenEffectParams Params)
	{
	}

	UFUNCTION(BlueprintPure)
	UNiagaraSystem GetCharacterOverlayDamageEffect()
	{
		return EffectSettings.OverlayDamageEffect;
	}

	UFUNCTION(BlueprintPure)
	UMaterialInterface GetCharacterOverlayDamageMaterial()
	{
		return EffectSettings.OverlayDamageMaterial;
	}

	UFUNCTION()
	void ShowPlayerOverlayMaterial(UMaterialInterface OverlayMaterial)
	{
		if (MeshesWithOverlayMaterial.Num() != 0)
			RemovePlayerOverlayMaterial();

		MeshesWithOverlayMaterial = VFX::FindAllRelevantPlayerMeshes(Player);
		for (auto MeshComp : MeshesWithOverlayMaterial)
		{
			if (!IsValid(MeshComp))
				continue;
			MeshComp.SetOverlayMaterial(OverlayMaterial);
		}
	}

	UFUNCTION()
	void RemovePlayerOverlayMaterial()
	{
		for (auto MeshComp : MeshesWithOverlayMaterial)
		{
			if (!IsValid(MeshComp))
				continue;
			MeshComp.SetOverlayMaterial(nullptr);
		}
		MeshesWithOverlayMaterial.Reset();
	}

	UFUNCTION(BlueprintPure)
	float GetDamageEffectAlphaCurve(float Health)
	{
		return DamageEffectCurve.GetFloatValue(Health);
	}
};