
/**
 * 
 */
enum EPlayerFocusTargetSettingsType
{
	AlwaysValid,
	IgnoreIfDead,
	FocusOnOtherAlivePlayerIfDead,
}

/**
 * 
*/
class UPlayerFocusTargetSettings : UHazeComposableSettings
{
	UPROPERTY()
	float HeightOffset = 0.95;

	/**
	 * When can this player be focused on
	 */
	UPROPERTY()
	EPlayerFocusTargetSettingsType FocusActivationType = EPlayerFocusTargetSettingsType::AlwaysValid;

	/**
	 * A global multiplier when this player is focused on
	 * Should be used to tweak the weight in runtime
	 */
	UPROPERTY()
	float WeightMultiplier = 1;
};


namespace PlayerFocus
{
	bool CanFocusOnPlayer(const AHazePlayerCharacter Player)
	{
		// During development, we can pick to only focus on 1 player always
		#if EDITOR
		auto DebugUser = UCameraDebugUserComponent::Get(Player);
		if(DebugUser != nullptr && DebugUser.FocusDebugType != NAME_None)
		{
			if(DebugUser.FocusDebugType == n"Disabled")
				return false;
			if(DebugUser.FocusDebugType == n"FocusOtherPlayer")
				return true;
		}
		#endif
		
		auto Settings = Cast<UPlayerFocusTargetSettings>(Player.TryGetSettings(UPlayerFocusTargetSettings));

		if (Settings == nullptr)
		{
			return true;
		}
		else if(Settings.FocusActivationType == EPlayerFocusTargetSettingsType::AlwaysValid)
		{
			return true;
		}

		// Only focus if we are alive
		else if(Settings.FocusActivationType == EPlayerFocusTargetSettingsType::IgnoreIfDead)
		{
			auto HealthComp = UPlayerHealthComponent::Get(Player);
			if (HealthComp != nullptr && HealthComp.bIsDead)
				return false;
		}

		// Focus other player if that player is alive
		else if(Settings.FocusActivationType == EPlayerFocusTargetSettingsType::FocusOnOtherAlivePlayerIfDead)
		{
			auto HealthComp = UPlayerHealthComponent::Get(Player);
			if (HealthComp != nullptr && HealthComp.bIsDead)
			{
				auto OtherHealthComp = UPlayerHealthComponent::Get(Player.OtherPlayer);
				if (OtherHealthComp != nullptr && !OtherHealthComp.bIsDead)
					return CanFocusOnPlayer(Player.OtherPlayer);
				else
					return false;
			}	
		}

		return true;
	}

	FVector GetPlayerFocusLocation(const AHazePlayerCharacter Player)
	{
		// During development, we can pick to only focus on 1 player always
		#if EDITOR
		auto DebugUser = UCameraDebugUserComponent::Get(Player);
		if(DebugUser != nullptr && DebugUser.FocusDebugType != NAME_None)
		{
			if(DebugUser.FocusDebugType == n"FocusOtherPlayer")
				return InternalGetter(Player.OtherPlayer);
		}
		#endif

		auto Settings = Cast<UPlayerFocusTargetSettings>(Player.TryGetSettings(UPlayerFocusTargetSettings));
		if (Settings == nullptr)
			return InternalGetter(Player);
		
		// Focus other player if that player is alive
		// The 'CanFocusOnPlayer' has already taken care of the validation
		if(Settings.FocusActivationType == EPlayerFocusTargetSettingsType::FocusOnOtherAlivePlayerIfDead)
		{
			auto HealthComp = UPlayerHealthComponent::Get(Player);
			if (HealthComp != nullptr && HealthComp.bIsDead)
			{
				auto OtherHealthComp = UPlayerHealthComponent::Get(Player.OtherPlayer);
				if (OtherHealthComp != nullptr && !OtherHealthComp.bIsDead)
				{
					return InternalGetter(Player.OtherPlayer);
				}
			}	
		}

		return InternalGetter(Player);
	}

	/**
	 * This function should only be used by internal focus location
	 */
	FVector InternalGetter(const AHazePlayerCharacter Player)
	{
		float HeightOffset = 0.95;

		{
			auto Settings = Cast<UPlayerFocusTargetSettings>(Player.TryGetSettings(UPlayerFocusTargetSettings));
			if (Settings != nullptr)
				HeightOffset = Settings.HeightOffset;
		}

		// Don't want to use head bone or something that will move with animation.
		FVector Offset = FVector(0.0, 0.0, Player.CapsuleComponent.GetUnscaledCapsuleHalfHeight() * HeightOffset);
		FTransform FocusRootTransform = Player.CapsuleComponent.GetWorldTransform();
		return FocusRootTransform.TransformPosition(Offset);
	}
}