
class UNetworkOverlay : UHazeUserWidget
{
	UFUNCTION(BlueprintPure)
	bool ShouldShowNetworkLabel()
	{
		if (!Debug::AreOnScreenMessagesEnabled())
			return false;

#if EDITOR
		if (Network::IsGameNetworked())
		{
			if(!SceneView::IsFullScreen() && Player.HasControl())
				return false;
		}
		FVector2D MinRect, MaxRect;
		SceneView::GetPercentageScreenRectFor(Player, MinRect, MaxRect);
		if (MaxRect.X - MinRect.X <= 0.25)
			return false;
		if (MaxRect.Y - MinRect.Y <= 0.25)
			return false;
		return true;
#else
		if (Player.HasControl())
			return false;
		return true;
#endif
	}
};