const express = require('express');
const app = express();
app.use(express.json());

app.post('/orgs/:owner/teams', (req, res) => {
  console.log(`Mock intercepted: POST /orgs/${req.params.owner}/teams`);
  console.log('Request headers:', JSON.stringify(req.headers));
  console.log('Request body:', JSON.stringify(req.body));

  // Validate request body
  const { name, description, privacy, notification_setting } = req.body;
  if (!name || !description || !privacy || !notification_setting) {
    return res.status(400).json({ message: 'Bad Request: Missing required fields in request body' });
  }

  // Simulate different responses based on team_name (name) and owner
  if (req.params.owner === 'test-owner' && name === 'test-team') {
    res.status(201).json({ id: 123, name: 'test-team', slug: 'test-team', description });
  } else if (name === 'existing-team') {
    res.status(422).json({ message: 'Unprocessable Entity: Team already exists' });
  } else {
    res.status(400).json({ message: 'Bad Request: Invalid team name or organization' });
  }
});

app.listen(3000, () => {
  console.log('Mock server listening on http://127.0.0.1:3000...');
});
