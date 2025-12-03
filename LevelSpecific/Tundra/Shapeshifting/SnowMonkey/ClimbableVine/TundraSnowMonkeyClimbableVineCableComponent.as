enum ETundraSnowMonkeyClimbableVineConstrainAxes
{
	X,
	Y,
	Z
}

class UTundraSnowMonkeyClimbableVineCableComponent : UHazeTEMPCableComponent
{
	// UPROPERTY(EditAnywhere, Meta=(Bitmask, BitmaskEnum="/Script/Angelscript.ETundraSnowMonkeyClimbableVineConstrainAxes"))
	// int ConstrainedAxes = 0;

	// UFUNCTION(BlueprintOverride)
	// bool GetEndPositions(FVector& OutStartPosition, FVector& OutEndPosition) const
	// {
	// 	bool bOverridden = false;

	// 	if(ConstrainedAxes & (1 << int(ETundraSnowMonkeyClimbableVineConstrainAxes::X)) != 0)
	// 	{
	// 		OutEndPosition.X = OutStartPosition.X;
	// 		bOverridden = true;
	// 	}
	// 	if(ConstrainedAxes & (1 << int(ETundraSnowMonkeyClimbableVineConstrainAxes::Y)) != 0)
	// 	{
	// 		OutEndPosition.Y = OutStartPosition.Y;
	// 		bOverridden = true;
	// 	}
	// 	if(ConstrainedAxes & (1 << int(ETundraSnowMonkeyClimbableVineConstrainAxes::Z)) != 0)
	// 	{
	// 		OutEndPosition.Z = OutStartPosition.Z;
	// 		bOverridden = true;
	// 	}

	// 	return bOverridden;
	// }
}