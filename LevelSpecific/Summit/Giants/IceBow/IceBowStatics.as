UFUNCTION()
void ActivateIceArrowTutorial(bool bActive)
{
	UIceArrowPlayerComponent IceArrowPlayerComp = UIceArrowPlayerComponent::Get(Game::GetPlayer(IceBow::Player));
	if (IceArrowPlayerComp == nullptr)
		return;

	IceArrowPlayerComp.bShowTutorial = bActive;
}

UFUNCTION()
void ActivateBlizzardArrowTutorial(bool bActive)
{
	UBlizzardArrowPlayerComponent BlizzardArrowPlayerComp = UBlizzardArrowPlayerComponent::Get(Game::GetPlayer(IceBow::Player));
	if (BlizzardArrowPlayerComp == nullptr)
		return;

	BlizzardArrowPlayerComp.bShowTutorial = bActive;
}

namespace IceBow
{
	bool ShouldIgnoreOtherPlayer()
    {
        FSphere ThisPlayerSphere = Game::GetPlayer(IceBow::Player).CapsuleComponent.GetBounds().Sphere;
        FSphere OtherPlayerSphere = Game::GetOtherPlayer(IceBow::Player).CapsuleComponent.GetBounds().Sphere;
        return ThisPlayerSphere.Intersects(OtherPlayerSphere);
    }
}