struct FBasicBehaviourCooldown
{
	float CooldownTime = 0.0;

	void Set(float Duration)
	{
		CooldownTime = Time::GameTimeSeconds + Duration;
	}

	bool IsOver() const
	{
		return (Time::GameTimeSeconds > CooldownTime);
	} 

	bool IsSet() const
	{
		if (CooldownTime == 0.0)
			return false;
		return true;
	}

	void Reset()
	{
		CooldownTime = 0.0;
	}
}
