	UFUNCTION(BlueprintPure)
	bool GetScreenWalkScreenPositionRelativePanningValue(
		bool bInsideOfScreen,
		FVector WorldLocation, 
		FVector2D& PreviousScreenPosition, float&out X, float&out Y)
	{
		auto ScreeenWalkManager = AMeltdownScreenWalkManager::Get();
		if (ScreeenWalkManager == nullptr)
			return false;

		FVector2D ScreenPosition;

		if (bInsideOfScreen)
		{
			if (!ScreeenWalkManager.ProjectSeethrough_InsideToScreenPosition(WorldLocation, false, ScreenPosition))
				return false;
		}
		else
		{
			if (!SceneView::ProjectWorldToViewpointRelativePosition(SceneView::FullScreenPlayer, WorldLocation, ScreenPosition))
				return false;
		}

		if (PreviousScreenPosition == ScreenPosition)
			return false;

		PreviousScreenPosition = ScreenPosition;

		const float XAlpha = Math::Saturate(ScreenPosition.X);
		const float XPanning = Math::Lerp(-1, 1, XAlpha);
		X = XPanning * Audio::GetPanningRuleMultiplier();

		const float YAlpha = Math::Saturate(ScreenPosition.Y);
		Y = Math::Lerp(-1.0, 1.0, YAlpha);

		return true;
	}