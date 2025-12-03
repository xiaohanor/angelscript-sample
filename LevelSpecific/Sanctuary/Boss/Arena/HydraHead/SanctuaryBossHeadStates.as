struct FSanctuaryBossHeadStates
{
	bool bDisableAfterDive = false;

	bool bShouldDive = false;
	bool bShouldSurface = false;
	bool bFreeStrangle = false;

	bool bToAttackApproach = false;
	bool bToAttackIdle = false;
	bool bToAttackRetract = false;
	bool bToAttackBiteLunge = false;
	bool bToAttackBiteDown = false;
	bool bToAttackBiteRetract = false;
	bool bToAttackProjectile = false;
	bool bToAttackSequenceAnticipation = false;
	bool bIncomingStrangle = false;

	bool bZoeStrangled = false;
	bool bZoeTightenStrangle = false;
	bool bMioStrangled = false;
	bool bMioTightenStrangle = false;

	bool bBleedDying = false;
	bool bDeath = false;
	bool bFriendDeath = false;

	bool bIsDecapitated = false;

	bool bShouldLaunchProjectile = false;
	bool bWaveAttack = false;
	bool bRainAttack = false;

	bool IsIdling() const 
	{
		if (bDisableAfterDive)
			return false;
		if (bShouldDive)
			return false;
		if (bShouldSurface)
			return false;
		if (bFreeStrangle)
			return false;
		if (bToAttackApproach)
			return false;
		if (bToAttackIdle)
			return false;
		if (bToAttackRetract)
			return false;
		if (bToAttackBiteLunge)
			return false;
		if (bToAttackBiteDown)
			return false;
		if (bToAttackBiteRetract)
			return false;
		if (bToAttackProjectile)
			return false;
		if (bToAttackSequenceAnticipation)
			return false;
		if (bIncomingStrangle)
			return false;
		if (bZoeStrangled)
			return false;
		if (bZoeTightenStrangle)
			return false;
		if (bMioStrangled)
			return false;
		if (bMioTightenStrangle)
			return false;
		if (bDeath)
			return false;
		if (bFriendDeath)
			return false;
		if (bIsDecapitated)
			return false;
		if (bShouldLaunchProjectile)
			return false;
		if (bWaveAttack)
			return false;
		if (bRainAttack)
			return false;
		return true;
	}

	bool Equals(const FSanctuaryBossHeadStates& Right) const
	{
		if (bDisableAfterDive != Right.bDisableAfterDive)
			return false;
		if (bShouldDive != Right.bShouldDive)
			return false;
		if (bShouldSurface != Right.bShouldSurface)
			return false;
		if (bFreeStrangle != Right.bFreeStrangle)
			return false;
		if (bToAttackApproach != Right.bToAttackApproach)
			return false;
		if (bToAttackIdle != Right.bToAttackIdle)
			return false;
		if (bToAttackRetract != Right.bToAttackRetract)
			return false;
		if (bToAttackBiteLunge != Right.bToAttackBiteLunge)
			return false;
		if (bToAttackBiteDown != Right.bToAttackBiteDown)
			return false;
		if (bToAttackBiteRetract != Right.bToAttackBiteRetract)
			return false;
		if (bToAttackProjectile != Right.bToAttackProjectile)
			return false;
		if (bToAttackSequenceAnticipation != Right.bToAttackSequenceAnticipation)
			return false;
		if (bIncomingStrangle != Right.bIncomingStrangle)
			return false;
		if (bZoeStrangled != Right.bZoeStrangled)
			return false;
		if (bZoeTightenStrangle != Right.bZoeTightenStrangle)
			return false;
		if (bMioStrangled != Right.bMioStrangled)
			return false;
		if (bMioTightenStrangle != Right.bMioTightenStrangle)
			return false;
		if (bDeath != Right.bDeath)
			return false;
		if (bFriendDeath != Right.bFriendDeath)
			return false;
		if (bIsDecapitated != Right.bIsDecapitated)
			return false;
		if (bShouldLaunchProjectile != Right.bShouldLaunchProjectile)
			return false;
		if (bWaveAttack != Right.bWaveAttack)
			return false;
		if (bRainAttack != Right.bRainAttack)
			return false;
		return true;
	}
}