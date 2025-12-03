UCLASS(Abstract)
class USummitKnightProjectileDamageEventHandler : UHazeEffectEventHandler
{
	TPerPlayer<UPlayerDamageScreenEffectComponent> ScreenEffectComps;

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerDamage(FSummitKnightProjectileDamageParams Params){};

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

struct FSummitKnightProjectileDamageParams
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player = nullptr;

	UPROPERTY(BlueprintReadOnly)
	float Damage = 0.0;

	UPROPERTY(BlueprintReadOnly)
	FVector Direction = FVector::ZeroVector;

	FSummitKnightProjectileDamageParams(AHazePlayerCharacter _Player, float _Damage, FVector Dir)
	{
		Player = _Player;
		Damage = _Damage;
		Direction = Dir;
	}
}
