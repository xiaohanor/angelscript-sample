class USkylineConstrainToScreenPlayerComponent : UActorComponent
{
	private bool bIsConstrainedHorizontal = true;
	private bool bIsConstrainedVertical = true;
	private bool bKillPlayerWhenFallingOut = true;
	private bool bRequestedKillPlayer = false;

	void SetKillPlayerWhenFallingOut(bool bKill)
	{
		bKillPlayerWhenFallingOut = bKill;
	}

	bool GetKillPlayerWhenFallingOut()
	{
		return bKillPlayerWhenFallingOut;
	}

	void SetIsConstrainedHorizontal(bool bConstrained)
	{
		bIsConstrainedHorizontal = bConstrained;
	}

	bool GetIsConstrainedHorizontal()
	{
		return bIsConstrainedHorizontal;
	}

	void SetIsConstrainedVertical(bool bConstrained)
	{
		bIsConstrainedVertical = bConstrained;
	}

	bool GetIsConstrainedVertical()
	{
		return bIsConstrainedVertical;
	}

	void SetRequestedKillPlayer(bool bKill)
	{
		bRequestedKillPlayer = bKill;
	}

	bool GetRequestedKillPlayer()
	{
		return bRequestedKillPlayer;
	}


}