class UFlyingCarHealthSettings : UHazeComposableSettings
{
	UPROPERTY()
	float RegenStartDelay = 2.0;

	UPROPERTY()
	float RegenDuration = 3.0;

	UPROPERTY()
	float InvincibilityAfterHitDuration = 1.0;
}

enum ESkylineFlyingCarDamageType
{
	Gunfire,
	Collision
}

USTRUCT()
struct FSkylineFlyingCarDamage
{
	UPROPERTY()
	float Amount;
}

event void FCarDamageEvent(FSkylineFlyingCarDamage CarDamage);
event void FCarExplosionEvent();

class USkylineFlyingCarHealthComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	const float MaxHealth = 1.0;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect HitForceFeedback;


	UPROPERTY()
	FCarDamageEvent OnCarDamaged;

	UPROPERTY()
	FCarExplosionEvent OnCarExplosion;

	UPROPERTY()
	FCarExplosionEvent OnCarRespawn;


	ASkylineFlyingCar CarOwner;

	access FlyingCarHealth = private, UFlyingCarHealthRegenerationCapability;
	access : FlyingCarHealth float CurrentHealth;

	access : FlyingCarHealth bool bTempInvincibility;

	// This is the previous frame where car took damage
	private uint LastDamageFrame;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CarOwner = Cast<ASkylineFlyingCar>(Owner);
		LastDamageFrame = 0;

		ResetHealth();
	}

	void UpdateHealth(float NewHealth)
	{
		CurrentHealth = NewHealth;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			auto DamageEffectComp = UPlayerDamageScreenEffectComponent::Get(Player);
			DamageEffectComp.OverrideDisplayedHealth.Apply(CurrentHealth, this);
			DamageEffectComp.OverrideLastDamageGameTime.Apply(Time::GameTimeSeconds, this);
			DamageEffectComp.bAllowInFullScreen.Apply(true, this);
		}
	}

	void TakeDamage(FSkylineFlyingCarDamage CarDamage, bool bIgnoreInvincibility = false)
	{
		if (bTempInvincibility && !bIgnoreInvincibility)
			return;

		// Avoid taking multiple hits on one frame
		if (LastDamageFrame == Time::FrameNumber)
			return;

		UpdateHealth(CurrentHealth - CarDamage.Amount);
		if (CurrentHealth > 0)
		{
			OnCarDamaged.Broadcast(CarDamage);

			LastDamageFrame = Time::FrameNumber;

			// Deal damage to John's fucking system
			if (CarOwner.Pilot != nullptr)
			{
				CarOwner.Pilot.DamagePlayerHealth(CarDamage.Amount);
				CarOwner.Pilot.OtherPlayer.DamagePlayerHealth(CarDamage.Amount);
			}

			Game::Zoe.PlayForceFeedback(HitForceFeedback, false, false, this, 1);
			Game::Mio.PlayForceFeedback(HitForceFeedback, false, false, this, 1);
			USkylineFlyingCarEventHandler::Trigger_OnTakeDamage(CarOwner, CarDamage);
		}
		else
		{
			// Die!
			if (HasControl())
			{
				CrumbExploreCar();

				// Lazily hook player respawn event
				// AHazePlayerCharacter Player = CarOwner.Pilot.HasControl() ? CarOwner.Pilot : CarOwner.Gunner;
				// UPlayerHealthComponent PlayerHealthComponent = UPlayerHealthComponent::Get(Player);
				// // PlayerHealthComponent.OnFinishDying.AddUFunction(this, n"OnPlayerFinishDying");
				// UPlayerRespawnComponent::Get(Player).OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawn");
			}
		}
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentHealth() const
	{
		return CurrentHealth;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbExploreCar()
	{
		// Fire event
		OnCarExplosion.Broadcast();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbRespawn()
	{
		ResetHealth();
		OnCarRespawn.Broadcast();
	}

	void ResetHealth()
	{
		CurrentHealth = MaxHealth;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			auto DamageEffectComp = UPlayerDamageScreenEffectComponent::Get(Player);
			DamageEffectComp.OverrideDisplayedHealth.Clear(this);
			DamageEffectComp.OverrideLastDamageGameTime.Clear(this);
			DamageEffectComp.bAllowInFullScreen.Clear(this);

		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerFinishDying()
	{
		CrumbRespawn();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		CrumbRespawn();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		PrintToScreenScaled("Health:" + CurrentHealth, 0.0, FLinearColor::Red, 7.0);
	}
}