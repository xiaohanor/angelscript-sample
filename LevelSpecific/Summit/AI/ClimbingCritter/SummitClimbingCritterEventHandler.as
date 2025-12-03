UCLASS(Abstract)
class USummitClimbingCritterEventHandler : UHazeEffectEventHandler
{
	TPerPlayer<UPlayerDamageScreenEffectComponent> ScreenEffectComps;

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerDamage(FSummitClimbingCritterDamagePlayerParams Params){};

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

struct FSummitClimbingCritterDamagePlayerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	FSummitClimbingCritterDamagePlayerParams(AHazePlayerCharacter _Player)
	{
		Player = _Player;
	}
}
