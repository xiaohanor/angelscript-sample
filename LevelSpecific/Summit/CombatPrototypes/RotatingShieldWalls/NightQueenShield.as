asset NightQueenShieldMeltSettings of UNightQueenMetalMeltingSettings
{
	Health = 2;
	RegrowthSpeed = 1.0;
	MeltingSpeed = 2.5;
	DissolvingSpeed = 2.5;
}

class ANightQueenShield : ANightQueenMetal
{
	UPROPERTY(DefaultComponent)
	UAttachOwnerToParentComponent AttachComp;

	default MetalMeltingSettings = NightQueenShieldMeltSettings;
}