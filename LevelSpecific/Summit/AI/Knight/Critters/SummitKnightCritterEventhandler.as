UCLASS(Abstract)
class USummitKnightCritterEventhandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartAttack(){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKillPlayer(){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLatchOnToPlayer(){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeath(){};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerDamage(FSummitKnightCritterDamagePlayerParams Params){};

	TPerPlayer<UPlayerDamageScreenEffectComponent> ScreenEffectComps;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ScreenEffectComps[Game::Mio] = UPlayerDamageScreenEffectComponent::GetOrCreate(Game::Mio);
		ScreenEffectComps[Game::Zoe] = UPlayerDamageScreenEffectComponent::GetOrCreate(Game::Zoe);
	}

	UFUNCTION(BlueprintPure)
	bool IsPastWidgetCooldown(AHazePlayerCharacter Player)
	{
		return Time::GameTimeSeconds > ScreenEffectComps[Player].Cooldown; 
	}

	UFUNCTION()
	void SetWidgetCooldown(AHazePlayerCharacter Player, float Cooldown)
	{
		ScreenEffectComps[Player].Cooldown = Time::GameTimeSeconds + Cooldown; 
	}
};

struct FSummitKnightCritterDamagePlayerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	FSummitKnightCritterDamagePlayerParams(AHazePlayerCharacter _Player)
	{
		Player = _Player;
	}
}
