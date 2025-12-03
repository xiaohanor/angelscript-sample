struct FCoastBossBulletMillZapPlayerParams
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class UCoastBossBulletMillEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	protected ACoastBossBulletMill Mill;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Mill = Cast<ACoastBossBulletMill>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawned() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ZapPlayer(FCoastBossBulletMillZapPlayerParams Params) {}
};