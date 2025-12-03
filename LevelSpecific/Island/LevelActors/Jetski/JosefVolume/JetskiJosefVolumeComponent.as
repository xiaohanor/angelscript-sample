enum EJetskiJosefVolumeDeathFromWallImpactsMode
{
	OnlyDieWhenJumpingFromUnderwater,
	NeverDie,
	Default,
}

UCLASS(NotBlueprintable)
class UJetskiJosefVolumeComponent : UHazeMovablePlayerTriggerComponent
{
	UPROPERTY(EditInstanceOnly)
	bool bUpJumpAcceleration = true;

	UPROPERTY(EditInstanceOnly)
	EJetskiJosefVolumeDeathFromWallImpactsMode DeathFromWallImpactsMode = EJetskiJosefVolumeDeathFromWallImpactsMode::OnlyDieWhenJumpingFromUnderwater;

	UFUNCTION(BlueprintOverride)
	void OnPlayerEnteredTrigger(AHazePlayerCharacter Player)
	{
		AJetski Jetski = Jetski::GetJetski(Player);
		if(Jetski == nullptr)
			return;

		Jetski.JosefVolumes.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerLeftTrigger(AHazePlayerCharacter Player)
	{
		AJetski Jetski = Jetski::GetJetski(Player);
		if(Jetski == nullptr)
			return;

		Jetski.JosefVolumes.Remove(this);
	}
};