class UMaxSecurityLaserCutterFocusGetter : UHazeCameraWeightedFocusTargetCustomGetter
{
	USceneComponent GetFocusComponent() const override
	{
		return nullptr;
	}

	FVector GetFocusLocation() const override
	{
		AMaxSecurityLaserCutter Cutter = MaxSecurityLaserCutter::GetLaserCutter();
		if (Cutter != nullptr)
			return Cutter.ImpactRoot.WorldLocation;

		return Game::Zoe.ActorLocation;
	}
}