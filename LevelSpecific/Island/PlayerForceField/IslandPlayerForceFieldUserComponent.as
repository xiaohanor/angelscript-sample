UCLASS(Abstract)
class UIslandPlayerForceFieldUserComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<AIslandPlayerForceFieldUIActor> UIActorClass;

	/* The red base color of the force field */
	UPROPERTY()
	FLinearColor RedColor = FLinearColor(100.0, 0.0, 0.0);

	/* The blue base color of the force field */
	UPROPERTY()
	FLinearColor BlueColor = FLinearColor(0.0, 3.948653, 25.0);

	/* The red fill color of the force field (when the shield is taking damage it uses this color) */
	UPROPERTY()
	FLinearColor RedFillColor = FLinearColor(5.0, 0.0, 1.0);

	/* The blue fill color of the force field (when the shield is taking damage it uses this color) */
	UPROPERTY()
	FLinearColor BlueFillColor = FLinearColor(5.0, 0.0, 0.0);

	AHazePlayerCharacter Player;
	UIslandForceFieldComponent ForceField;
	UPlayerHealthComponent HealthComp;
	bool bForceFieldActive = false;
	bool bForceFieldIsDestroyed = false;
	float TimeOfLastForceFieldDamage = -1.0;
	AIslandPlayerForceFieldUIActor UIActor;
	private float Internal_ForceFieldFadeAlpha = 1.0;
	bool bAlwaysOnForceFieldActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ForceField = UIslandForceFieldComponent::Get(Player);
		HealthComp = UPlayerHealthComponent::Get(Player);
	}

	void SetForceFieldFadeAlpha(float Alpha) property
	{
		Internal_ForceFieldFadeAlpha = Alpha;
		ForceField.SetScalarParameterValueOnMaterials(n"FadeAlpha", Alpha);
	}

	float GetForceFieldFadeAlpha() property
	{
		return Internal_ForceFieldFadeAlpha;
	}

	void TakeDamagePoison(float DeltaTime, float ForceFieldDamagePerSec, float PlayerDamagePerSec)
	{
		if(bForceFieldActive)
		{
			ForceField.TakeDamage(ForceFieldDamagePerSec * DeltaTime, Player.Mesh.GetSocketLocation(n"Head"), Player, true);
			TimeOfLastForceFieldDamage = Time::GetGameTimeSeconds();

			if(ForceField.IsDepleted())
			{
				ForceField.TriggerBurstEffect();
				bForceFieldIsDestroyed = true;
			}
		}
		else
			HealthComp.DamagePlayer(PlayerDamagePerSec * DeltaTime, nullptr, nullptr);
	}

	void TakeDamageBullet(float ForceFieldDamage, float PlayerDamage, FVector DamageLocation)
	{
		if(bForceFieldActive)
		{
			ForceField.TakeDamage(ForceFieldDamage, DamageLocation, Instigator = Player);
			ForceField.Impact(DamageLocation);
			TimeOfLastForceFieldDamage = Time::GetGameTimeSeconds();

			if(ForceField.IsDepleted())
			{
				ForceField.TriggerBurstEffect();
				bForceFieldIsDestroyed = true;
			}
		}
		else
			HealthComp.DamagePlayer(PlayerDamage, nullptr, nullptr);
	}

	void TakeDamageLaser(FVector HitLocation, float DamagePerSecond, float DamageInterval)
	{
		if(bForceFieldActive)
		{
			ForceField.TakeDamage(DamagePerSecond * DamageInterval, HitLocation, Instigator = Player);
			ForceField.Impact(HitLocation);
			TimeOfLastForceFieldDamage = Time::GetGameTimeSeconds();

			if(ForceField.IsDepleted())
			{
				ForceField.TriggerBurstEffect();
				bForceFieldIsDestroyed = true;
			}
		}
		else
			HealthComp.DealBatchedDamage(DamagePerSecond * DamageInterval, FPlayerDeathDamageParams());
	}

	UFUNCTION()
	void ActivateAlwaysOnForceField()
	{
		bAlwaysOnForceFieldActive = true;
	}

	UFUNCTION()
	void DeactivateAlwaysOnForceField()
	{
		bAlwaysOnForceFieldActive = false;
	}

	UFUNCTION(BlueprintPure)
	bool IsAlwaysOnForceFieldActive()
	{
		return bAlwaysOnForceFieldActive;
	}
}