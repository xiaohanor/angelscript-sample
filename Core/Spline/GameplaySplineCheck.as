namespace Spline
{
	/**
	 * Find the spline component on the specified that should be used for gameplay.
	 * Will give errors if that spline component is marked as editor-only.
	 */
	UHazeSplineComponent GetGameplaySpline(const AActor Actor)
	{
#if EDITOR
		return GetGameplaySpline(Actor, Debug::EditorGetAngelscriptStackFrameObject(1));
#else
		return GetGameplaySpline(Actor, FInstigator());
#endif
	}

	/**
	 * Find the spline component on the specified that should be used for gameplay.
	 * Will give errors if that spline component is marked as editor-only.
	 */
	UHazeSplineComponent GetGameplaySpline(const AActor Actor, FInstigator Instigator)
	{
		if (Actor == nullptr)
		{
			// If the actor is null this is not an error for us, but on the upper level
			return nullptr;
		}

		auto SplineComp = UHazeSplineComponent::Get(Actor);
		if (SplineComp == nullptr)
		{
#if EDITOR
			devError(f"{Instigator} is using gameplay spline from Actor {Actor.ActorLabel}, which has no spline component.");
#else
			devError(f"{Instigator} is using gameplay spline from Actor {Actor.Name}, which has no spline component.");
#endif
			return nullptr;
		}

#if EDITOR
		if (SplineComp.bIsEditorOnly)
		{
			auto PropLine = Cast<APropLine>(Actor);
			if (PropLine != nullptr)
			{
				if (!PropLine.bGameplaySpline)
					devError(f"{Instigator} is using spline from {PropLine.ActorLabel} for gameplay, but the propline does not have `Gameplay Spline` checked!\nThis will break cooked.");
			}
			else
			{
				devError(f"{Instigator} is using an editor-only spline component for gameplay, this will break cooked. Spline: {SplineComp.GetPathName()}");
			}
		}
#endif

		return SplineComp;
	}
}