class UPlayerOutlineSettings : UHazeComposableSettings
{
	UPROPERTY()
	bool bPlayerOutlineVisible = false;
}

asset VisiblePlayerOutlineSettings of UPlayerOutlineSettings
{
	bPlayerOutlineVisible = true;
}