class UHoverPerchPlayerComponent : UActorComponent
{
	AHoverPerchActor PerchActor;
}

namespace HoverPerch
{
	UFUNCTION(BlueprintPure)
	AHoverPerchActor GetCurrentPerchForPlayer(AHazePlayerCharacter Player)
	{
		auto HoverPerchComp = UHoverPerchPlayerComponent::GetOrCreate(Player);
		return HoverPerchComp.PerchActor;
	}
}