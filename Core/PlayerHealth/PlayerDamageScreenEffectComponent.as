class UPlayerDamageScreenEffectComponent : UActorComponent
{
	TInstigated<bool> bAllowInFullScreen;
	default bAllowInFullScreen.DefaultValue = false;

	TInstigated<float> OverrideDisplayedHealth;
	TInstigated<float> OverrideLastDamageGameTime;
	
	float Cooldown = -BIG_NUMBER;
};
