namespace GiantsStatics
{
	UFUNCTION(DisplayName = "Giants Skydive Set Magnet Point", Category = "Giants|Skydive")
	void BP_SetPlayerMagnetPoint(AHazePlayerCharacter Player, AGiantsSkydiveMagnetPoint MagnetPoint)
	{
		devCheck(MagnetPoint != nullptr, "No magnet point set!");
		UGiantsSkydiveMagnetPlayerComponent Comp = UGiantsSkydiveMagnetPlayerComponent::GetOrCreate(Player);
		Comp.SetMagnetPoint(MagnetPoint);
	}
}