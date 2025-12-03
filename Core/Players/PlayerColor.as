namespace PlayerColor
{
	const FLinearColor Mio = FLinearColor::MakeFromHex(0xffee009a);
	const FLinearColor Zoe = FLinearColor::MakeFromHex(0xffcaf431);
	const FLinearColor BothPlayers = FLinearColor(1.0, 0.664, 0.051, 1.0);
}

UFUNCTION(BlueprintPure)
FLinearColor GetColorForBothPlayers()
{
	return PlayerColor::BothPlayers;
}

UFUNCTION(BlueprintPure)
FLinearColor GetColorForPlayer(EHazePlayer Player)
{
	if (Player == EHazePlayer::Mio)
		return PlayerColor::Mio;
	else
		return PlayerColor::Zoe;
}

UFUNCTION(BlueprintPure, DisplayName = "Get Player UI Color")
mixin FLinearColor GetPlayerUIColor(const AHazePlayerCharacter Player)
{
	return GetColorForPlayer(Player.Player);
}

UFUNCTION(BlueprintPure)
mixin FLinearColor GetPlayerDebugColor(const AHazePlayerCharacter Player)
{
	return GetColorForPlayer(Player.Player);
}