UCLASS(Abstract)
class USkylineGeckoEffectHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnEntryLand() {}

    // The owner took damage (SkylineGecko.OnTakeDamage)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTakeDamage() {}

	// The owner has been thrown into a wall and will die soon
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPreDeath() {}

	// The owner died 
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath() {}

	// The owner took damage (SkylineGecko.OnStunnedStart)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStunnedStart() {}

	// The owner took damage (SkylineGecko.OnStunnedStop)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStunnedStop() {}

	// The owner took damage (SkylineGecko.OnStunnedStart)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnOverturnedStart() {}

	// The owner took damage (SkylineGecko.OnStunnedStop)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnOverturnedStop() {}

	// The owner is preparing to pounce
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraphPounce() {}

	// The owner starts a pounce attack
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPounceStart() {}

	// The owner lands after pounce and can start hitting target
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPounceLand() {}

	// Pounce attack hits a target
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPounceAttackHit(FSkylineGeckoEffectHandlerOnPounceData Data) {}

	// The owner finishes pounce attack
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPounceEnd() {}


    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnConstrainPlayerTelegraph(FSkylineGeckoEffectHandlerOnPounceData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnConstrainPlayerStart(FSkylineGeckoEffectHandlerOnPounceData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnConstrainPlayerEnd() {}


    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDakkaAttackTelegraph(FGeckoDakkaProjectileLaunch Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDakkaAttackBurstStart(FGeckoDakkaProjectileLaunch Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDakkaAttackLaunchProjectile(FGeckoDakkaProjectileLaunch Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDakkaAttackBurstEnd(FGeckoDakkaProjectileLaunch Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDakkaAttackDone(FGeckoDakkaProjectileLaunch Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnBlobAttackTelegraph(FGeckoBlobProjectileLaunch Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnBlobAttackLaunchProjectile(FGeckoBlobProjectileLaunch Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGravityWhipGrabbed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGravityWhipThrown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGravityWhipThrownImpact() {}
}

struct FGeckoBlobProjectileLaunch
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	USkylineGeckoBlobLauncherComponent Launcher;

	FGeckoBlobProjectileLaunch(USkylineGeckoBlobLauncherComponent _Launcher)
	{
		Launcher = _Launcher;
		Location = Launcher.LaunchLocation;
	}
}

struct FSkylineGeckoEffectHandlerOnPounceData
{
	UPROPERTY()
	AHazePlayerCharacter PlayerTarget;

	FSkylineGeckoEffectHandlerOnPounceData(AHazePlayerCharacter _PlayerTarget)
	{
		PlayerTarget = _PlayerTarget;
	}
}

struct FGeckoDakkaProjectileLaunch
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	USkylineGeckoDakkaLauncherComponent Launcher;

	FGeckoDakkaProjectileLaunch(USkylineGeckoDakkaLauncherComponent _Launcher)
	{
		Launcher = _Launcher;
		Location = Launcher.LaunchLocation;
	}
}
