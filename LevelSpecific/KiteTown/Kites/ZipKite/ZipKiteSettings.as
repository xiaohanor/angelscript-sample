class UPlayerZipKiteSettings : UHazeComposableSettings
{
	const float AdditionalMashPlayerVerticalOffset = 300;

	//How much of our aligned velocity at maximum we let influence the Blendspace (to give room for the additional sway based on time + mashrate)
	const float MaxBlendSpaceAffectFromVelocity = 650;

	//How much additional lerping sway we have in the "Swing" BS
	const float AdditionalAnimSway = 200;

	const float MashRateInterpSpeed = 0.75;

	const float ZipSpeedDecelerationInterpSpeed = 2000;
	const float ZipSpeedAccelerationInterpSpeed = 1250;

	const float ZipSwingUpMinimumVelocity = 2000;

	const float AerialExitMinDuration = 1.2;
	const float AerialExitMaxDuration = 1.5;
}
