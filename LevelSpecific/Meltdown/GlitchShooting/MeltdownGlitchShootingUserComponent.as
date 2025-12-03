struct FMeltdownPlayerGlitchIndicatorSettings
{
	UPROPERTY()
	TSubclassOf<AMeltdownPlayerGlitchIndicator> IndicatorClass;
	UPROPERTY()
	FName AttachSocket;
	UPROPERTY()
	FTransform AttachTransform;
}

class UMeltdownGlitchShootingUserComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<AMeltdownGlitchShootingProjectile> ProjectileClass;
	UPROPERTY()
	TSubclassOf<AMeltdownGlitchShootingProjectile> ProjectileClass_Rocket;
	UPROPERTY()
	TSubclassOf<AMeltdownGlitchShootingProjectile> ProjectileClass_Missile;
	UPROPERTY()
	TSubclassOf<UMeltdownGlitchShootingCrosshair> CrosshairClass;

	UPROPERTY()
	TArray<FMeltdownPlayerGlitchIndicatorSettings> IndicatorSettings;

	UPROPERTY()
	TSubclassOf<AMeltdownGlitchShootingWeapon> WeaponClass;

	UPROPERTY()
	UForceFeedbackEffect ChargedForceFeedback;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ChargedShake;

	UPROPERTY()
	UForceFeedbackEffect FireForceFeedback;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> FireShake;

	UMeltdownGlitchShootingSettings ShootingSettings;
	

	FVector AimDirection;

	TArray<AMeltdownPlayerGlitchIndicator> Indicators;
	bool bGlitchShootingActive = false;
	bool bIsShooting = false;
	bool bCutsceneAiming = false;

	AMeltdownGlitchShootingWeapon Weapon;
	TInstigated<bool> WeaponVisibility;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		ShootingSettings = UMeltdownGlitchShootingSettings::GetSettings(Player);
	}

	void InitializeIndicators()
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		for (auto Settings : IndicatorSettings)
		{
			AMeltdownPlayerGlitchIndicator Indicator = SpawnActor(Settings.IndicatorClass);
			Indicator.AttachToComponent(Player.Mesh, Settings.AttachSocket);
			Indicator.SetActorRelativeTransform(Settings.AttachTransform);
			Indicators.Add(Indicator);
		}
	}

	void ActivateGlitchShooting()
	{
		bGlitchShootingActive = true;
		UpdateIndicators();
	}

	void DeactivateGlitchShooting()
	{
		bGlitchShootingActive = false;
		UpdateIndicators();
	}

	UFUNCTION(BlueprintCallable)
	void BlueprintActivateShooting()
	{
		bGlitchShootingActive = true;
		UpdateIndicators();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateIndicators();
	}

	void UpdateIndicators()
	{
		for (int i = 0, Count = Indicators.Num(); i < Count; ++i)
		{
			if (bGlitchShootingActive)
			{
				Indicators[i].ActivateIndicator();
			}
			else
			{
				Indicators[i].DeactivateIndicator();
			}
		}
	}

	UFUNCTION(DevFunction, NotBlueprintCallable)
	private void DevActivateGlitchShooting()
	{
		for (auto Player : Game::Players)
			UMeltdownGlitchShootingUserComponent::Get(Player).ActivateGlitchShooting();
	}
};

namespace MeltdownGlitchShooting
{

UFUNCTION(DisplayName = "Meltdown Activate Glitch Shooting")
void ActivateGlitchShooting(AHazePlayerCharacter Player)
{
	auto UserComp = UMeltdownGlitchShootingUserComponent::Get(Player);
	UserComp.ActivateGlitchShooting();
}

UFUNCTION(DisplayName = "Meltdown Deactivate Glitch Shooting")
void DeactivateGlitchShooting(AHazePlayerCharacter Player)
{
	auto UserComp = UMeltdownGlitchShootingUserComponent::Get(Player);
	UserComp.DeactivateGlitchShooting();
}

}